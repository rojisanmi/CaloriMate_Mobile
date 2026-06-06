import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _api = ApiClient.instance;

  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  int _role = 1; // 0=admin, 1=client, 2=trainer

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get client {
    final c = _user?['client'];
    if (c is Map) return Map<String, dynamic>.from(c);
    return null;
  }
  Map<String, dynamic>? get trainer {
    final t = _user?['trainer'];
    if (t is Map) return Map<String, dynamic>.from(t);
    return null;
  }
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  int get role => _role;
  bool get isClient => _role == 1;
  bool get isTrainer => _role == 2;
  bool get isAdmin => _role == 0;
  String get displayName => _user?['username'] as String? ?? 'User';

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      if (await _auth.isLoggedIn()) {
        final prefs = await SharedPreferences.getInstance();
        _role = prefs.getInt('user_role') ?? 1;
        await _fetchProfileByRole();
      }
    } catch (_) {
      await _auth.logout();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _fetchProfileByRole() async {
    if (_role == 2) {
      await fetchTrainerProfile();
    } else {
      await fetchProfile();
    }
  }

  Future<void> fetchProfile() async {
    final res = await _api.get('/client/profile');
    final data = res.data as Map<String, dynamic>;
    _user = data['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> fetchTrainerProfile() async {
    final res = await _api.get('/trainer/profile');
    final data = res.data as Map<String, dynamic>;
    _user = data['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<bool> login(String username, String password, {int role = 1}) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _auth.login(username: username, password: password, role: role);
      final user = data['user'] as Map<String, dynamic>;
      final userRole = (user['role'] as num?)?.toInt() ?? role;

      // Block Admin from mobile
      if (userRole == 0) {
        await _auth.logout();
        _error = 'Admin tidak diizinkan login di aplikasi mobile.';
        _loading = false;
        notifyListeners();
        return false;
      }

      _role = userRole;
      _user = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_role', _role);
      await _fetchProfileByRole();
      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required double tb,
    required double bb,
    required String gender,
    required int umur,
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _auth.registerClient(
        username: username,
        email: email,
        password: password,
        tinggiBadan: tb,
        beratBadan: bb,
        gender: gender,
        umur: umur,
      );
      _user = data['user'] as Map<String, dynamic>;
      _role = 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_role', _role);
      await fetchProfile();
      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAsTrainer({
    required String username,
    required String email,
    required String password,
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _auth.registerTrainer(
        username: username,
        email: email,
        password: password,
      );
      _user = data['user'] as Map<String, dynamic>;
      _role = 2;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_role', _role);
      await fetchTrainerProfile();
      _loading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _parseError(e);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    _user = null;
    _role = 1;
    notifyListeners();
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
    }
    return 'Terjadi kesalahan. Periksa koneksi dan coba lagi.';
  }
}
