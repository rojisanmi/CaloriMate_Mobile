import '../services/api_service.dart';

class StatisticService {
  static Future<Map<String, dynamic>> getStatistics() async {
    return await ApiService.get('/client/statistic');
  }
}
