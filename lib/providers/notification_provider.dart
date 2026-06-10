import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/// Provider that exposes the unread-notification count to the widget tree
/// and controls the polling lifecycle in [NotificationService].
class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;

  /// Current number of unread notifications (shown as badge).
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    NotificationService.instance.onUnreadCountChanged = (count) {
      _unreadCount = count;
      notifyListeners();
    };
  }

  /// Begin polling for unread notifications (call once the client is logged in).
  void startPolling() {
    NotificationService.instance.startPolling();
  }

  /// Stop the polling timer.
  void stopPolling() {
    NotificationService.instance.stopPolling();
  }

  /// Reset state on logout.
  void reset() {
    _unreadCount = 0;
    stopPolling();
    notifyListeners();
  }
}
