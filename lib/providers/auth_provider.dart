import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _api = ApiClient.instance;

  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get client {
    final c = _user?['client'];
    if (c is Map) return Map<String, dynamic>.from(c);
    return null;
  }
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get displayName => _user?['username'] as String? ?? 'User';

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    try {
      if (await _auth.isLoggedIn()) {
        await fetchProfile();
      }
    } catch (_) {
      await _auth.logout();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final res = await _api.get('/client/profile');
    final data = res.data as Map<String, dynamic>;
    _user = data['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _auth.login(username: username, password: password);
      _user = data['user'] as Map<String, dynamic>;
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

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
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
