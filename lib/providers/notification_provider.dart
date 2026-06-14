import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

/// Provider that manages notification scheduling lifecycle.
/// No longer does polling — reminders are scheduled directly
/// into Android's AlarmManager via [NotificationService].
class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// Fetch the unread notification count from the server and notify listeners
  /// so badges (e.g. on the bell icon) update.
  Future<void> refreshUnread() async {
    try {
      final res = await ApiClient.instance.get('/client/notifications/unread');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        _unreadCount = (data['unread_count'] as num?)?.toInt() ?? 0;
        notifyListeners();
      }
    } catch (_) {
      // Abaikan error jaringan — badge cukup tetap di nilai terakhir.
    }
  }

  /// Set unread count to zero locally (mis. setelah "tandai semua dibaca").
  void clearUnread() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  /// Cancel all scheduled reminders (call on logout).
  Future<void> reset() async {
    await NotificationService.instance.cancelAll();
    _unreadCount = 0;
    notifyListeners();
  }
}
