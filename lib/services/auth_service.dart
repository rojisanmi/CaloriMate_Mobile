import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    int role = 1,
  }) async {
    final res = await _api.post('/login', data: {
      'username': username,
      'password': password,
      'role': role,
    });
    final data = res.data as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'] as String);
    await prefs.setString('user_json', data['user'].toString());
    return data;
  }

  Future<Map<String, dynamic>> registerClient({
    required String username,
    required String email,
    required String password,
    required double tinggiBadan,
    required double beratBadan,
    required String gender,
    required int umur,
  }) async {
    final res = await _api.post('/register/client', data: {
      'username': username,
      'email': email,
      'password': password,
      'tinggi_badan': tinggiBadan,
      'berat_badan': beratBadan,
      'gender': gender,
      'umur': umur,
    });
    final data = res.data as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token'] as String);
    return data;
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }
}
