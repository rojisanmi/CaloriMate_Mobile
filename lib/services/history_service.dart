import '../services/api_service.dart';

class HistoryService {
  static Future<Map<String, dynamic>> getHistory({String period = 'daily'}) async {
    return await ApiService.get('/client/history?period=$period');
  }
}
