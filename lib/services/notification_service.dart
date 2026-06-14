import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Membersihkan alarm reminder lokal lama. Sejak migrasi ke FCM, reminder
/// makan/olahraga dikirim sebagai push dari server (lihat [PushService]),
/// bukan lagi alarm lokal — jadi service ini hanya bertugas membatalkan
/// alarm lama yang mungkin masih terjadwal di AlarmManager perangkat.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // ID alarm lokal lama untuk tiap tipe reminder.
  static const int _foodNotifId = 1001;
  static const int _exerciseNotifId = 1002;

  /// Inisialisasi plugin (diperlukan agar pembatalan notifikasi berfungsi).
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  /// Batalkan semua notifikasi lokal (mis. saat logout).
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await _clearPrefs();
  }

  /// Batalkan HANYA alarm reminder lokal (makan & olahraga) yang mungkin masih
  /// terjadwal dari versi sebelum migrasi ke FCM, tanpa menyentuh notif lain.
  Future<void> cancelLocalReminders() async {
    await _plugin.cancel(_foodNotifId);
    await _plugin.cancel(_exerciseNotifId);
    await _clearPrefs();
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('schedule_food');
    await prefs.remove('schedule_exercise');
  }
}
