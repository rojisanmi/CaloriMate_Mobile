import '../services/api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get('/client/profile');
  }

  static Future<Map<String, dynamic>> updateProfile({
    required double bb,
    required double tb,
    required int umur,
    String? gender,
  }) async {
    final body = <String, String>{
      'bb': bb.toString(),
      'tb': tb.toString(),
      'umur': umur.toString(),
    };
    if (gender != null) body['gender'] = gender;
    return await ApiService.post('/client/profile', body);
  }
}
