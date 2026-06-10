import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Singleton service that polls the server for unread notifications,
/// displays them via flutter_local_notifications, and marks them as read.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  Set<int> _shownIds = {};

  /// Callback invoked whenever the unread count changes.
  void Function(int count)? onUnreadCountChanged;

  /// Initialise the plugin and load previously-shown IDs from disk.
  Future<void> init() async {
    await _loadShownIds();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Request permission for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Polling control ──────────────────────────────────────────────────

  /// Start the 60-second polling loop (polls immediately on first call).
  void startPolling() {
    _timer?.cancel();
    _poll(); // fire immediately
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _poll());
  }

  /// Stop polling (e.g. on logout).
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Core poll logic ──────────────────────────────────────────────────

  Future<void> _poll() async {
    try {
      final response =
          await ApiClient.instance.get('/client/notifications/unread');
      final data = response.data;
      if (data is! Map<String, dynamic>) return;

      final notifications = data['notifications'] as List? ?? [];
      final unreadCount = data['unread_count'] as int? ?? 0;

      // Notify provider of current unread count
      onUnreadCountChanged?.call(unreadCount);

      for (final notif in notifications) {
        final id = notif['id'] as int;
        if (_shownIds.contains(id)) continue;

        await _showNotification(
          id,
          notif['title'] ?? '',
          notif['message'] ?? '',
        );
        _shownIds.add(id);

        // Best-effort mark as read on the server
        try {
          await ApiClient.instance
              .post('/client/notifications/read', data: {'id': id});
        } catch (_) {}
      }

      await _saveShownIds();
    } catch (_) {
      // Network or parse errors – silently retry on next tick
    }
  }

  // ── Local notification display ───────────────────────────────────────

  Future<void> _showNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'calorimate_reminders',
      'Pengingat CaloriMate',
      channelDescription: 'Notifikasi pengingat dari CaloriMate',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // ── Persistence helpers ──────────────────────────────────────────────

  Future<void> _saveShownIds() async {
    final prefs = await SharedPreferences.getInstance();
    // Prevent unbounded growth – keep only the latest 200 IDs
    if (_shownIds.length > 200) {
      _shownIds =
          _shownIds.toList().sublist(_shownIds.length - 200).toSet();
    }
    await prefs.setString('shown_notification_ids', _shownIds.join(','));
  }

  Future<void> _loadShownIds() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('shown_notification_ids') ?? '';
    if (str.isNotEmpty) {
      _shownIds =
          str.split(',').map((s) => int.tryParse(s)).whereType<int>().toSet();
    }
  }

  /// Clear all persisted shown-ID state (useful on logout).
  void clearShownIds() async {
    _shownIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shown_notification_ids');
  }
}
