import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/// Provider that manages notification scheduling lifecycle.
/// No longer does polling — reminders are scheduled directly
/// into Android's AlarmManager via [NotificationService].
class NotificationProvider extends ChangeNotifier {
  /// Sync reminder schedules from the server and register
  /// them with the OS alarm system. Call once after login.
  Future<void> syncSchedules() async {
    await NotificationService.instance.syncFromServer();
  }

  /// Cancel all scheduled reminders (call on logout).
  Future<void> reset() async {
    await NotificationService.instance.cancelAll();
    notifyListeners();
  }
}
