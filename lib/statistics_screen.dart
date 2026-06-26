import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ---------------------------------------------------------------------------
// AppColors — exact same as main.dart dashboard
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// API base URL — same server as dashboard
// ---------------------------------------------------------------------------
class _Api {
  static const base     = 'http://125.209.66.147:5001/api';
  static const loginUrl = 'http://125.209.66.147:5001/api/auth/signin';

  // All endpoints used in this screen
  static const vendors      = '$base/users/vendors';
  // GET /users/vendors
  // Response expected: [ { "id": 68, "name": "Vendor Name" }, ... ]
  // Used for: Vendor dropdown

  static const statuses     = '$base/shopboard-requests/statuses';
  // GET /shopboard-requests/statuses
  // Response expected: [ { "value": "additional_director_approval", "label": "Additional Director Approval" }, ... ]
  // Used for: Status dropdown

  static const regions      = '$base/regions';
  // GET /regions
  // Response expected: [ { "name": "Lahore" }, ... ]  OR  [ "Lahore", "Karachi", ... ]
  // Used for: Region dropdown

  static const parentDealers = '$base/dealers/by-region/parents';
  // GET /dealers/by-region/parents?region=Abbottabad
  // Response expected: [ { "code": "C0174200", "name": "Dealer Name" }, ... ]
  // Used for: Parent Dealer dropdown (loaded after region is selected)

  static const childDealers  = '$base/dealers/by-region/children';
  // GET /dealers/by-region/children?parent_code=C0174200
  // Response expected: [ { "code": "C0003381", "name": "Child Dealer Name" }, ... ]
  // Used for: Child Dealer dropdown (loaded after parent dealer is selected)

  static const salesHeads    = '$base/all-areaheads';
  // GET /all-areaheads
  // Response expected: [ { "code": "Gm07.0-Bwp", "name": "Area Head Name" }, ... ]
  // Used for: Sales Head dropdown

  static const statistics    = '$base/statistics';
  // GET /statistics?vendor_id=68&status=additional_director_approval&region=Lahore
  //                &parent_dealer_code=C0003380&child_dealer_code=C0003381
  //                &sales_head_code=Gm07.0-Bwp&start_date=2026-06-01&end_date=2026-06-23
  // Used for: fetching total requests and total cost after Apply is tapped
}

// ---------------------------------------------------------------------------
// Token manager — same pattern as dashboard _TokenManager
// ---------------------------------------------------------------------------
class _TokenManager {
  static String?   _token;
  static DateTime? _expiresAt;

  static Future<String> getToken() async {
    if (_token != null &&
        _expiresAt != null &&
        DateTime.now().isBefore(_expiresAt!)) {
      return _token!;
    }
    return _fetch();
  }

  static void invalidate() {
    _token     = null;
    _expiresAt = null;
  }

  static Future<String> _fetch() async {
    final res = await http
        .post(
          Uri.parse(_Api.loginUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'usernameOrEmail': 'superadmin',
            'password'       : 'admin123',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body  = jsonDecode(res.body);
      final token = body['token']             ??
                    body['accessToken']        ??
                    body['data']?['token']     ??
                    body['data']?['accessToken'];
      if (token == null) throw Exception('Token not found in login response');
      _token     = token as String;
      _expiresAt = DateTime.now().add(const Duration(minutes: 55));
      return _token!;
    }
    throw Exception('Login failed — ${res.statusCode}');
  }

  static Map<String, String> headers(String token) => {
    'Content-Type' : 'application/json',
    'Authorization': 'Bearer $token',
  };
}

// ---------------------------------------------------------------------------
// Statistics Screen
// ---------------------------------------------------------------------------
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {

  // ── Selected filter values ─────────────────────────────────────────────────
  // Each filter stores the full map so we have both display name and code/id
  Map<String, dynamic>? _selVendor;        // { 'id': 68, 'name': '...' }
  Map<String, dynamic>? _selStatus;        // { 'value': 'approval', 'label': '...' }
  String?               _selRegion;        // region name string e.g. "Lahore"
  Map<String, dynamic>? _selParentDealer;  // { 'code': 'C0174200', 'name': '...' }
  Map<String, dynamic>? _selChildDealer;   // { 'code': 'C0003381', 'name': '...' }
  Map<String, dynamic>? _selSalesHead;     // { 'code': 'Gm07.0-Bwp', 'name': '...' }
  DateTimeRange?         _selDateRange;

  // ── Dropdown item lists ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _vendors       = [];
  List<Map<String, dynamic>> _statuses      = [];
  List<String>               _regions       = [];
  List<Map<String, dynamic>> _parentDealers = [];
  List<Map<String, dynamic>> _childDealers  = [];
  List<Map<String, dynamic>> _salesHeads    = [];

  // ── Loading flags for each dropdown ───────────────────────────────────────
  bool _loadingVendors       = false;
  bool _loadingStatuses      = false;
  bool _loadingRegions       = false;
  bool _loadingParentDealers = false;
  bool _loadingChildDealers  = false;
  bool _loadingSalesHeads    = false;

  // ── Statistics result ──────────────────────────────────────────────────────
  int    _totalRequests = 0;
  double _totalCost     = 0.0;
  bool   _statsLoading  = false;
  bool   _statsError    = false;
  String _statsErrorMsg = '';
  bool   _statsFetched  = false; // true after first successful fetch

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _filtersExpanded = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Load all independent dropdowns when screen opens
    _fetchVendors();
    _fetchStatuses();
    _fetchRegions();
    _fetchSalesHeads();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // API: Fetch vendors
  // Endpoint: GET /api/users/vendors
  // Vendor dropdown list
  // --------------------------------------------------------------------------
  Future<void> _fetchVendors() async {
    setState(() => _loadingVendors = true);
    try {
      final token = await _TokenManager.getToken();
      final res   = await http
          .get(Uri.parse(_Api.vendors),
               headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Handle both array root and wrapped response
        final List raw = body is List ? body : (body['data'] ?? body['vendors'] ?? []);
        setState(() {
          _vendors = raw.map<Map<String, dynamic>>((e) => {
            'id'  : e['id']?.toString()   ?? '',
            'name': e['name']?.toString() ?? e['username']?.toString() ?? '',
          }).where((e) => e['name']!.isNotEmpty).toList();
        });
      }
    } catch (_) {
      // Silently fail — dropdown stays empty, user can still use other filters
    } finally {
      if (mounted) setState(() => _loadingVendors = false);
    }
  }

  // --------------------------------------------------------------------------
  // API: Fetch statuses
  // Endpoint: GET /api/shopboard-requests/statuses
  // Status dropdown list
  // --------------------------------------------------------------------------
  Future<void> _fetchStatuses() async {
    setState(() => _loadingStatuses = true);
    try {
      final token = await _TokenManager.getToken();
      final res   = await http
          .get(Uri.parse(_Api.statuses),
               headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List raw = body is List ? body : (body['data'] ?? body['statuses'] ?? []);
        setState(() {
          _statuses = raw.map<Map<String, dynamic>>((e) {
            if (e is String) return {'value': e, 'label': e};
            // Actual API response uses: slug + displayName
            final value = e['slug']?.toString()        ??
                          e['value']?.toString()        ??
                          e['id']?.toString()           ?? '';
            final label = e['displayName']?.toString() ??
                          e['label']?.toString()        ??
                          e['name']?.toString()         ??
                          value;
            return {'value': value, 'label': label};
          }).where((e) => e['label']!.isNotEmpty).toList();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingStatuses = false);
    }
  }

  // --------------------------------------------------------------------------
  // API: Fetch regions
  // Endpoint: GET /api/regions
  // Region dropdown list
  // --------------------------------------------------------------------------
  Future<void> _fetchRegions() async {
    setState(() => _loadingRegions = true);
    try {
      final token = await _TokenManager.getToken();
      final res   = await http
          .get(Uri.parse(_Api.regions),
               headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List raw = body is List ? body : (body['data'] ?? body['regions'] ?? []);
        setState(() {
          // Regions may be plain strings or objects with name field
          _regions = raw.map<String>((e) {
            if (e is String) return e;
            return e['name']?.toString() ?? '';
          }).where((e) => e.isNotEmpty).toList();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  // --------------------------------------------------------------------------
  // API: Fetch parent dealers
  // Endpoint: GET /api/dealers/by-region/parents?region=Abbottabad
  // Called automatically when region is selected
  // Clears child dealers when called
  // --------------------------------------------------------------------------
  Future<void> _fetchParentDealers(String regionName) async {
    setState(() {
      _loadingParentDealers = true;
      _parentDealers        = [];
      _selParentDealer      = null;
      _childDealers         = [];
      _selChildDealer       = null;
    });
    try {
      final token = await _TokenManager.getToken();
      final uri   = Uri.parse(_Api.parentDealers)
          .replace(queryParameters: {'region': regionName});
      final res   = await http
          .get(uri, headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List raw = body is List ? body : (body['data'] ?? body['dealers'] ?? []);
        setState(() {
          _parentDealers = raw.map<Map<String, dynamic>>((e) => {
            'code': e['code']?.toString() ?? e['dealer_code']?.toString() ?? '',
            'name': e['name']?.toString() ?? e['dealer_name']?.toString() ?? '',
          }).where((e) => e['code']!.isNotEmpty).toList();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingParentDealers = false);
    }
  }

  // --------------------------------------------------------------------------
  // API: Fetch child dealers
  // Endpoint: GET /api/dealers/by-region/children?parent_code=C0174200
  // Called automatically when parent dealer is selected
  // --------------------------------------------------------------------------
  Future<void> _fetchChildDealers(String parentCode) async {
    setState(() {
      _loadingChildDealers = true;
      _childDealers        = [];
      _selChildDealer      = null;
    });
    try {
      final token = await _TokenManager.getToken();
      final uri   = Uri.parse(_Api.childDealers)
          .replace(queryParameters: {'parent_code': parentCode});
      final res   = await http
          .get(uri, headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List raw = body is List ? body : (body['data'] ?? body['dealers'] ?? []);
        setState(() {
          _childDealers = raw.map<Map<String, dynamic>>((e) => {
            'code': e['code']?.toString() ?? e['dealer_code']?.toString() ?? '',
            'name': e['name']?.toString() ?? e['dealer_name']?.toString() ?? '',
          }).where((e) => e['code']!.isNotEmpty).toList();
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingChildDealers = false);
    }
  }

  // --------------------------------------------------------------------------
  // API: Fetch sales heads (area heads)
  // Endpoint: GET /api/all-areaheads
  // Sales Head dropdown list
  // --------------------------------------------------------------------------
  Future<void> _fetchSalesHeads() async {
    setState(() => _loadingSalesHeads = true);
    try {
      final token = await _TokenManager.getToken();
      final res   = await http
          .get(Uri.parse(_Api.salesHeads),
               headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final List raw = body is List ? body : (body['data'] ?? body['areaHeads'] ?? body['area_heads'] ?? []);
        // Each area head has sh_name and sh_codes (array of codes)
        // Expand each code into a separate dropdown item so user can pick exact code
        final expanded = <Map<String, dynamic>>[];
        for (final e in raw) {
          final name  = e['sh_name']?.toString() ?? '';
          final codes = e['sh_codes'];
          if (codes is List && codes.isNotEmpty) {
            for (final c in codes) {
              final code = c?.toString() ?? '';
              if (code.isNotEmpty) {
                expanded.add({
                  'code': code,
                  'name': '$name ($code)',  // display: "Ghulam Muhammad (Gm07.0-Bwp)"
                });
              }
            }
          }
        }
        setState(() {
          _salesHeads = expanded;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingSalesHeads = false);
    }
  }

  // --------------------------------------------------------------------------
  // API: Fetch statistics with current filters
  // Endpoint: GET /api/statistics
  // Query params: vendor_id, status, region, parent_dealer_code,
  //               child_dealer_code, sales_head_code, start_date, end_date
  // Called when user taps the Apply button
  // --------------------------------------------------------------------------
  Future<void> _fetchStatistics() async {
    setState(() {
      _statsLoading = true;
      _statsError   = false;
      _statsErrorMsg= '';
    });

    try {
      final token = await _TokenManager.getToken();

      // Build query parameters — only include filters that are selected
      final params = <String, String>{};

      if (_selVendor != null && _selVendor!['id']!.isNotEmpty)
        params['vendor_id'] = _selVendor!['id']!;

      if (_selStatus != null && _selStatus!['value']!.isNotEmpty)
        params['status'] = _selStatus!['value']!;

      if (_selRegion != null && _selRegion!.isNotEmpty)
        params['region'] = _selRegion!;

      if (_selParentDealer != null && _selParentDealer!['code']!.isNotEmpty)
        params['parent_dealer_code'] = _selParentDealer!['code']!;

      if (_selChildDealer != null && _selChildDealer!['code']!.isNotEmpty)
        params['child_dealer_code'] = _selChildDealer!['code']!;

      if (_selSalesHead != null && _selSalesHead!['code']!.isNotEmpty)
        params['sales_head_code'] = _selSalesHead!['code']!;

      if (_selDateRange != null) {
        // Format: 2026-06-01
        params['start_date'] =
            _selDateRange!.start.toIso8601String().split('T')[0];
        params['end_date'] =
            _selDateRange!.end.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse(_Api.statistics)
          .replace(queryParameters: params.isEmpty ? null : params);

      var res = await http
          .get(uri, headers: _TokenManager.headers(token))
          .timeout(const Duration(seconds: 15));

      // Retry once if token expired (401)
      if (res.statusCode == 401) {
        _TokenManager.invalidate();
        final newToken = await _TokenManager.getToken();
        res = await http
            .get(uri, headers: _TokenManager.headers(newToken))
            .timeout(const Duration(seconds: 15));
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Response shape: { "success": true, "data": { "totalRequests": 0, "totalCost": 0 } }
        final data = body['data'] is Map ? body['data'] : body;
        setState(() {
          _totalRequests = ((data['totalRequests'] ?? data['total_requests'] ?? data['count'] ?? 0) as num).toInt();
          _totalCost     = ((data['totalCost']     ?? data['total_cost']     ?? data['cost']  ?? 0) as num).toDouble();
          _statsLoading  = false;
          _statsFetched  = true;
        });
      } else {
        setState(() {
          _statsLoading  = false;
          _statsError    = true;
          _statsErrorMsg = 'Server returned ${res.statusCode}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsLoading  = false;
          _statsError    = true;
          _statsErrorMsg = e.toString();
        });
      }
    }
  }

  // --------------------------------------------------------------------------
  // Called when region dropdown changes
  // Resets parent and child dealers, then fetches new parent dealers
  // --------------------------------------------------------------------------
  void _onRegionChanged(String? regionName) {
    setState(() {
      _selRegion       = regionName;
      _selParentDealer = null;
      _selChildDealer  = null;
      _parentDealers   = [];
      _childDealers    = [];
    });
    if (regionName != null && regionName.isNotEmpty) {
      _fetchParentDealers(regionName);
    }
  }

  // --------------------------------------------------------------------------
  // Called when parent dealer dropdown changes
  // Fetches child dealers based on selected parent code
  // --------------------------------------------------------------------------
  void _onParentDealerChanged(Map<String, dynamic>? dealer) {
    setState(() {
      _selParentDealer = dealer;
      _selChildDealer  = null;
      _childDealers    = [];
    });
    if (dealer != null && dealer['code']!.isNotEmpty) {
      _fetchChildDealers(dealer['code']!);
    }
  }

  // --------------------------------------------------------------------------
  // Remove a single active filter chip
  // --------------------------------------------------------------------------
  void _removeFilter(String key) {
    setState(() {
      switch (key) {
        case 'vendor':
          _selVendor = null;
          break;
        case 'status':
          _selStatus = null;
          break;
        case 'region':
          // Clearing region also clears dependent dealers
          _selRegion       = null;
          _selParentDealer = null;
          _selChildDealer  = null;
          _parentDealers   = [];
          _childDealers    = [];
          break;
        case 'parent':
          // Clearing parent also clears child
          _selParentDealer = null;
          _selChildDealer  = null;
          _childDealers    = [];
          break;
        case 'child':
          _selChildDealer = null;
          break;
        case 'salesHead':
          _selSalesHead = null;
          break;
        case 'date':
          _selDateRange = null;
          break;
      }
    });
  }

  // --------------------------------------------------------------------------
  // Clear all filters at once
  // --------------------------------------------------------------------------
  void _clearAll() {
    setState(() {
      _selVendor       = null;
      _selStatus       = null;
      _selRegion       = null;
      _selParentDealer = null;
      _selChildDealer  = null;
      _selSalesHead    = null;
      _selDateRange    = null;
      _parentDealers   = [];
      _childDealers    = [];
      _totalRequests   = 0;
      _totalCost       = 0.0;
      _statsFetched    = false;
      _statsError      = false;
    });
  }

  // --------------------------------------------------------------------------
  // Build active filter chip data for display
  // --------------------------------------------------------------------------
  List<Map<String, String>> get _activeFilters {
    final list = <Map<String, String>>[];
    if (_selVendor       != null) list.add({'key': 'vendor',     'label': 'Vendor: ${_selVendor!['name']}'});
    if (_selStatus       != null) list.add({'key': 'status',     'label': 'Status: ${_selStatus!['label']}'});
    if (_selRegion       != null) list.add({'key': 'region',     'label': 'Region: $_selRegion'});
    if (_selParentDealer != null) list.add({'key': 'parent',     'label': 'Parent: ${_selParentDealer!['name']}'});
    if (_selChildDealer  != null) list.add({'key': 'child',      'label': 'Child: ${_selChildDealer!['name']}'});
    if (_selSalesHead    != null) list.add({'key': 'salesHead',  'label': 'Sales Head: ${_selSalesHead!['name']}'});
    if (_selDateRange    != null) {
      final s = _selDateRange!.start;
      final e = _selDateRange!.end;
      list.add({
        'key'  : 'date',
        'label': '${s.day}/${s.month}/${s.year} – ${e.day}/${e.month}/${e.year}',
      });
    }
    return list;
  }

  // --------------------------------------------------------------------------
  // Open system date range picker
  // --------------------------------------------------------------------------
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(2020),
      lastDate:         DateTime.now(),
      initialDateRange: _selDateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary:   AppColors.primary,
            onPrimary: Colors.white,
            surface:   AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selDateRange = picked);
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFiltersCard(),
                      const SizedBox(height: 16),
                      // Show result cards only after Apply has been tapped
                      if (_statsError)
                        _buildErrorCard()
                      else ...[
                        _buildStatCard(
                          icon:       Icons.receipt_long_rounded,
                          iconColor:  AppColors.accent,
                          iconBg:     AppColors.accentLight,
                          label:      'TOTAL REQUESTS',
                          value:      '$_totalRequests',
                          isLoading:  _statsLoading,
                        ),
                        const SizedBox(height: 12),
                        _buildStatCard(
                          icon:       Icons.payments_rounded,
                          iconColor:  AppColors.success,
                          iconBg:     const Color(0xFFE8F5E9),
                          label:      'TOTAL COST',
                          value:      'Rs ${_totalCost.toStringAsFixed(2)}',
                          isLoading:  _statsLoading,
                          valueColor: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Top bar — back button + title + Apply button
  // Matches dashboard top bar style exactly
  // --------------------------------------------------------------------------
  Widget _buildTopBar() {
    return Container(
      color:   AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width:  36,
              height: 36,
              decoration: BoxDecoration(
                color:        AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.7),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textMuted, size: 17),
            ),
          ),
          const SizedBox(width: 12),
          // Screen title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Statistics',
                style: TextStyle(
                    color:      AppColors.textHead,
                    fontSize:   16,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'Requests & Cost Overview',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
          // Apply filters button — triggers _fetchStatistics
          GestureDetector(
            onTap: _fetchStatistics,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2B4A), Color(0xFF243B5E)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color:      AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset:     const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'Apply',
                    style: TextStyle(
                        color:      Colors.white,
                        fontSize:   12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Filters card — collapsible, contains all 7 filters
  // --------------------------------------------------------------------------
  Widget _buildFiltersCard() {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Filters header row ───────────────────────────────────────────
          GestureDetector(
            onTap:     () => setState(() => _filtersExpanded = !_filtersExpanded),
            behavior:  HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color:        AppColors.accentLight,
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.filter_list_rounded,
                        color: AppColors.accent, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Filters',
                    style: TextStyle(
                        color:      AppColors.textHead,
                        fontSize:   14,
                        fontWeight: FontWeight.w700),
                  ),
                  // Badge showing count of active filters
                  if (_activeFilters.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color:        AppColors.accent,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '${_activeFilters.length}',
                        style: const TextStyle(
                            color:      Colors.white,
                            fontSize:   10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_activeFilters.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAll,
                      child: Row(
                        children: const [
                          Icon(Icons.close_rounded,
                              size: 13, color: AppColors.red),
                          SizedBox(width: 3),
                          Text(
                            'Clear All',
                            style: TextStyle(
                                color:      AppColors.red,
                                fontSize:   11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _filtersExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                    size:  20,
                  ),
                ],
              ),
            ),
          ),

          if (_filtersExpanded) ...[
            Container(height: 0.7, color: AppColors.border),
            const SizedBox(height: 6),

            // 1. Vendor — /api/users/vendors
            _buildDropdownGeneric<Map<String, dynamic>>(
              label:        'Vendor',
              icon:         Icons.store_rounded,
              selectedItem: _selVendor,
              items:        _vendors,
              isLoading:    _loadingVendors,
              hint:         'Select vendor',
              displayText:  (item) => item['name'] ?? '',
              onChanged:    (v) => setState(() => _selVendor = v),
            ),

            // 2. Status — /api/shopboard-requests/statuses
            _buildDropdownGeneric<Map<String, dynamic>>(
              label:        'Status',
              icon:         Icons.check_circle_outline_rounded,
              selectedItem: _selStatus,
              items:        _statuses,
              isLoading:    _loadingStatuses,
              hint:         'Select status',
              displayText:  (item) => item['label'] ?? '',
              onChanged:    (v) => setState(() => _selStatus = v),
            ),

            // 3. Region — /api/regions
            _buildStringDropdown(
              label:     'Region',
              icon:      Icons.location_on_outlined,
              value:     _selRegion,
              items:     _regions,
              isLoading: _loadingRegions,
              hint:      'Select region',
              onChanged: _onRegionChanged,
            ),

            // 4. Date Range — date picker (no API, sent as start_date/end_date)
            _buildDateField(),

            // 5. Parent Dealer — /api/dealers/by-region/parents?region=X
            //    Enabled only when region is selected
            _buildDropdownGeneric<Map<String, dynamic>>(
              label:        'Parent Dealer',
              icon:         Icons.business_rounded,
              selectedItem: _selParentDealer,
              items:        _parentDealers,
              isLoading:    _loadingParentDealers,
              hint:         _selRegion == null
                  ? 'Select region first'
                  : 'Select parent dealer',
              enabled:      _selRegion != null,
              displayText:  (item) => item['name'] ?? '',
              onChanged:    _onParentDealerChanged,
            ),

            // 6. Child Dealer — /api/dealers/by-region/children?parent_code=X
            //    Enabled only when parent dealer is selected
            _buildDropdownGeneric<Map<String, dynamic>>(
              label:        'Child Dealer',
              icon:         Icons.person_outline_rounded,
              selectedItem: _selChildDealer,
              items:        _childDealers,
              isLoading:    _loadingChildDealers,
              hint:         _selParentDealer == null
                  ? 'Select parent dealer first'
                  : 'Select child dealer',
              enabled:      _selParentDealer != null,
              displayText:  (item) => item['name'] ?? '',
              onChanged:    (v) => setState(() => _selChildDealer = v),
            ),

            // 7. Sales Head — /api/all-areaheads
            _buildDropdownGeneric<Map<String, dynamic>>(
              label:        'Sales Head',
              icon:         Icons.supervisor_account_rounded,
              selectedItem: _selSalesHead,
              items:        _salesHeads,
              isLoading:    _loadingSalesHeads,
              hint:         'Select sales head',
              displayText:  (item) => item['name'] ?? '',
              onChanged:    (v) => setState(() => _selSalesHead = v),
            ),

            const SizedBox(height: 8),

            // Active filter chips
            if (_activeFilters.isNotEmpty) ...[
              Container(height: 0.7, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE FILTERS',
                      style: TextStyle(
                          color:         AppColors.textMuted,
                          fontSize:      9.5,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing:    8,
                      runSpacing: 8,
                      children:   _activeFilters
                          .map((f) => _StatsFilterChip(
                                label:    f['label']!,
                                onRemove: () => _removeFilter(f['key']!),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Generic dropdown builder for Map-based items (vendor, status, dealers, salesHead)
  // --------------------------------------------------------------------------
  Widget _buildDropdownGeneric<T extends Map<String, dynamic>>({
    required String              label,
    required IconData            icon,
    required T?                  selectedItem,
    required List<T>             items,
    required bool                isLoading,
    required String              hint,
    required String Function(T)  displayText,
    required ValueChanged<T?>    onChanged,
    bool                         enabled = true,
  }) {
    final bool hasValue = selectedItem != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize:     10.5,
                fontWeight:   FontWeight.w600,
                letterSpacing: 0.3,
                color: enabled ? AppColors.accent : AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.surfaceAlt,
              border: Border.all(
                  color: hasValue
                      ? AppColors.accent
                      : enabled
                          ? AppColors.border
                          : AppColors.divider,
                  width: hasValue ? 1.2 : 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isLoading
                ? _loadingRow()
                : DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value:      selectedItem,
                      isExpanded: true,
                      hint: _hintRow(icon, hint, enabled),
                      selectedItemBuilder: (_) => items
                          .map((item) => _selectedRow(icon, displayText(item)))
                          .toList(),
                      items: enabled
                          ? items
                              .map((item) => DropdownMenuItem<T>(
                                    value: item,
                                    child: Text(
                                      displayText(item),
                                      style: const TextStyle(
                                          color:    AppColors.textBody,
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList()
                          : [],
                      onChanged: enabled ? onChanged : null,
                      icon: _dropIcon(enabled),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // String-based dropdown builder — used for Region (plain string list)
  // --------------------------------------------------------------------------
  Widget _buildStringDropdown({
    required String              label,
    required IconData            icon,
    required String?             value,
    required List<String>        items,
    required bool                isLoading,
    required String              hint,
    required ValueChanged<String?> onChanged,
  }) {
    final bool hasValue = value != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize:     10.5,
                fontWeight:   FontWeight.w600,
                color:        AppColors.accent,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                  color: hasValue ? AppColors.accent : AppColors.border,
                  width: hasValue ? 1.2 : 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isLoading
                ? _loadingRow()
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value:      value,
                      isExpanded: true,
                      hint: _hintRow(icon, hint, true),
                      selectedItemBuilder: (_) => items
                          .map((item) => _selectedRow(icon, item))
                          .toList(),
                      items: items
                          .map((item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                      color:    AppColors.textBody,
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: onChanged,
                      icon: _dropIcon(true),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Date range picker field
  // --------------------------------------------------------------------------
  Widget _buildDateField() {
    final hasDate = _selDateRange != null;
    String display = 'Select date range';
    if (hasDate) {
      final s = _selDateRange!.start;
      final e = _selDateRange!.end;
      display = '${s.day}/${s.month}/${s.year}  –  ${e.day}/${e.month}/${e.year}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
                fontSize:     10.5,
                fontWeight:   FontWeight.w600,
                color:        AppColors.accent,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              height:  46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                    color: hasDate ? AppColors.accent : AppColors.border,
                    width: hasDate ? 1.2 : 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size:  15,
                      color: hasDate ? AppColors.accent : AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(
                          fontSize:   12,
                          color:      hasDate
                              ? AppColors.textHead
                              : AppColors.textMuted,
                          fontWeight: hasDate
                              ? FontWeight.w600
                              : FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasDate)
                    GestureDetector(
                      onTap: () => setState(() => _selDateRange = null),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textMuted),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Result stat card — shown after Apply is tapped
  // --------------------------------------------------------------------------
  Widget _buildStatCard({
    required IconData icon,
    required Color    iconColor,
    required Color    iconBg,
    required String   label,
    required String   value,
    required bool     isLoading,
    Color?            valueColor,
  }) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  54,
            height: 54,
            decoration: BoxDecoration(
                color:        iconBg,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color:         AppColors.textMuted,
                      fontSize:      9.5,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: 5),
                isLoading
                    ? Container(
                        width:  90,
                        height: 24,
                        decoration: BoxDecoration(
                            color:        AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(6)))
                    : Text(
                        value,
                        style: TextStyle(
                            color:      valueColor ?? AppColors.textHead,
                            fontSize:   26,
                            fontWeight: FontWeight.w800),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Error card — shown when statistics API call fails
  // --------------------------------------------------------------------------
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.redLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.red.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not load statistics',
                  style: TextStyle(
                      color:      AppColors.red,
                      fontSize:   13,
                      fontWeight: FontWeight.w600),
                ),
                if (_statsErrorMsg.isNotEmpty)
                  Text(
                    _statsErrorMsg,
                    style: const TextStyle(
                        color: AppColors.red, fontSize: 10),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchStatistics,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color:        AppColors.red,
                  borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'Retry',
                style: TextStyle(
                    color:      Colors.white,
                    fontSize:   11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Hint card — shown before first Apply tap
  // --------------------------------------------------------------------------
  Widget _buildHintCard() {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color:        AppColors.accentLight,
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.bar_chart_rounded,
                color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select filters and tap Apply',
            style: TextStyle(
                color:      AppColors.textHead,
                fontSize:   14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Statistics will appear here',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Small shared helper widgets
  // --------------------------------------------------------------------------

  // Loading spinner row shown inside dropdown while fetching
  Widget _loadingRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width:  13,
            height: 13,
            child:  CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.accent),
          ),
          SizedBox(width: 10),
          Text('Loading...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  // Hint text row inside dropdown when nothing is selected
  Widget _hintRow(IconData icon, String hint, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon,
              size:  14,
              color: enabled ? AppColors.textMuted : AppColors.border),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                  fontSize: 12,
                  color: enabled ? AppColors.textMuted : AppColors.border),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Selected value row shown inside dropdown after selection
  Widget _selectedRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color:      AppColors.textHead,
                  fontSize:   12,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Dropdown arrow icon
  Widget _dropIcon(bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: enabled ? AppColors.textMuted : AppColors.border,
        size:  20,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip widget — shown in active filters section
// ---------------------------------------------------------------------------
class _StatsFilterChip extends StatelessWidget {
  final String       label;
  final VoidCallback onRemove;

  const _StatsFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:        AppColors.warningLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.45), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize:   11,
                  color:      Color(0xFF6D4C41),
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: Color(0xFF6D4C41)),
          ),
        ],
      ),
    );
  }
}