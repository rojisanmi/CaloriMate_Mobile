import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class ApiService {

  // =========================
  // HEADER
  // =========================

  static Future<Map<String, String>> headers() async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =========================
  // GET REQUEST
  // =========================

  static Future<dynamic> get(String endpoint) async {

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await headers(),
    );

    return jsonDecode(response.body);
  }

  // =========================
  // POST REQUEST
  // =========================

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await headers(),
      body: body,
    );

    return jsonDecode(response.body);
  }

  // =========================
  // PUT REQUEST
  // =========================

  static Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {

    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await headers(),
      body: body,
    );

    return jsonDecode(response.body);
  }

  // =========================
  // DELETE REQUEST
  // =========================

  static Future<dynamic> delete(String endpoint) async {

    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await headers(),
    );

    return jsonDecode(response.body);
  }
}