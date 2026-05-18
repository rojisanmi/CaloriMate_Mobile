import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class AuthService {

  // =========================
  // LOGIN
  // =========================

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required int role,
  }) async {

    try {

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/login'),

        headers: {
          'Accept': 'application/json',
        },

        body: {
          'username': username,
          'password': password,
          'role': role.toString(),
        },
      );

      final data = jsonDecode(response.body);

      // Login berhasil
      if (response.statusCode == 200) {

        final prefs = await SharedPreferences.getInstance();

        // Simpan token
        await prefs.setString(
          'token',
          data['data']['token'],
        );

        return data;

      } else {

        return {
          'success': false,
          'message': data['message'] ?? 'Login gagal',
        };
      }

    } catch (e) {

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // =========================
  // LOGOUT
  // =========================

  static Future<void> logout() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
  }

  // =========================
  // GET TOKEN
  // =========================

  static Future<String?> getToken() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  // =========================
  // CHECK LOGIN
  // =========================

  static Future<bool> isLoggedIn() async {

    final token = await getToken();

    return token != null;
  }
}