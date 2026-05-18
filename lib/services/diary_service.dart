import '../services/api_service.dart';

class DiaryService {
  static Future<Map<String, dynamic>> getDiary() async {
    return await ApiService.get('/client/diary');
  }

  static Future<Map<String, dynamic>> addFood({
    required int foodId,
    required int portions,
    required String category,
  }) async {
    return await ApiService.post('/client/diary', {
      'food_id': foodId.toString(),
      'portions': portions.toString(),
      'category': category,
    });
  }

  static Future<Map<String, dynamic>> removeFood({
    required int foodId,
    required String category,
  }) async {
    return await ApiService.delete('/client/diary?food_id=$foodId&category=$category');
  }

  static Future<List<dynamic>> searchFoods(String query) async {
    final result = await ApiService.get('/client/diary/search?q=$query');
    if (result is List) return result;
    return result['data'] ?? [];
  }
}
