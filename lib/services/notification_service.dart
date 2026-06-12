import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'api_client.dart';

/// Singleton service that schedules daily local notifications
/// using Android's AlarmManager (via zonedSchedule).
/// Notifications fire even when the app is closed or minimized.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // Fixed notification IDs for each reminder type
  static const int _foodNotifId = 1001;
  static const int _exerciseNotifId = 1002;

  /// Initialise timezone data, the plugin, and request permission.
  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Request permission for Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request exact alarm permission for Android 12+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ── Schedule reminders ──────────────────────────────────────────────

  /// Schedule a daily food reminder at the given [time].
  /// If [time] is null, cancels the existing food reminder.
  Future<void> scheduleFoodReminder(TimeOfDay? time) async {
    if (time == null) {
      await _plugin.cancel(_foodNotifId);
      await _saveSchedule('food', null);
      return;
    }

    await _scheduleDailyNotification(
      id: _foodNotifId,
      hour: time.hour,
      minute: time.minute,
      title: 'Pengingat Input Makanan',
      body: 'Waktunya mencatat makanan kamu! Jangan lupa input makanan hari ini ya 🍽️',
    );
    await _saveSchedule('food', time);
  }

  /// Schedule a daily exercise reminder at the given [time].
  /// If [time] is null, cancels the existing exercise reminder.
  Future<void> scheduleExerciseReminder(TimeOfDay? time) async {
    if (time == null) {
      await _plugin.cancel(_exerciseNotifId);
      await _saveSchedule('exercise', null);
      return;
    }

    await _scheduleDailyNotification(
      id: _exerciseNotifId,
      hour: time.hour,
      minute: time.minute,
      title: 'Pengingat Jadwal Olahraga',
      body: 'Saatnya berolahraga! Ayo jaga kebugaran tubuhmu hari ini 💪',
    );
    await _saveSchedule('exercise', time);
  }

  /// Sync reminder schedules from the server profile.
  /// Call this when the app opens / user logs in.
  Future<void> syncFromServer() async {
    try {
      final response = await ApiClient.instance.get('/client/profile');
      final data = response.data;
      if (data is! Map<String, dynamic>) return;

      final client = data['client'] ?? data;
      final foodTime = _parseTime(client['food_reminder_time']?.toString());
      final exerciseTime = _parseTime(client['exercise_reminder_time']?.toString());

      await scheduleFoodReminder(foodTime);
      await scheduleExerciseReminder(exerciseTime);
    } catch (_) {
      // If server is unreachable, restore from local storage
      await _restoreFromLocal();
    }
  }

  /// Restore scheduled notifications from locally saved times.
  /// Used as fallback when server is unreachable.
  Future<void> _restoreFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final foodStr = prefs.getString('schedule_food');
    final exerciseStr = prefs.getString('schedule_exercise');

    if (foodStr != null) {
      final t = _parseTime(foodStr);
      if (t != null) await scheduleFoodReminder(t);
    }
    if (exerciseStr != null) {
      final t = _parseTime(exerciseStr);
      if (t != null) await scheduleExerciseReminder(t);
    }
  }

  /// Cancel all scheduled reminders (e.g. on logout).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('schedule_food');
    await prefs.remove('schedule_exercise');
  }

  // ── Internal helpers ────────────────────────────────────────────────

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'calorimate_reminders_v2',
      'Pengingat CaloriMate',
      channelDescription: 'Notifikasi pengingat dari CaloriMate',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('cm'),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Persist schedule to SharedPreferences for offline restore.
  Future<void> _saveSchedule(String type, TimeOfDay? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time == null) {
      await prefs.remove('schedule_$type');
    } else {
      final str =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await prefs.setString('schedule_$type', str);
    }
  }

  /// Parse "HH:MM" or "HH:MM:SS" string to TimeOfDay.
  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}
