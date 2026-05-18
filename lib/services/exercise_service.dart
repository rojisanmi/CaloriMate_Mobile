import '../services/api_service.dart';

class ExerciseService {
  static Future<List<dynamic>> getPrograms() async {
    final result = await ApiService.get('/client/exercise');
    if (result is List) return result;
    return [];
  }

  static Future<Map<String, dynamic>> getProgramDetail(int id) async {
    return await ApiService.get('/client/exercise/$id');
  }

  static Future<Map<String, dynamic>> startProgram(int id) async {
    return await ApiService.post('/client/exercise/$id/start', {});
  }
}
