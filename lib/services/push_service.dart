import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

/// Handler pesan FCM saat app di background/terminated.
/// Pesan dengan payload `notification` otomatis ditampilkan oleh sistem Android,
/// jadi di sini tidak perlu aksi tambahan.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Intent navigasi dari hasil tap notifikasi reminder ('food' / 'exercise').
/// MainShell mendengarkan ini lalu berpindah ke tab yang sesuai.
final ValueNotifier<String?> reminderNavIntent = ValueNotifier<String?>(null);

/// Mengelola Firebase Cloud Messaging: registrasi token ke server &
/// menampilkan notifikasi push saat app sedang dibuka (foreground).
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _fln = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'calorimate_reminders_v3',
    'Pengingat CaloriMate',
    description: 'Notifikasi pengingat dari CaloriMate',
    importance: Importance.high,
    sound: RawResourceAndroidNotificationSound('cm'),
  );

  /// Siapkan channel, izin, dan listener. Panggil sekali saat app start.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Inisialisasi plugin lokal + tangani tap notifikasi foreground.
    await _fln.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (resp) => _routeTo(resp.payload),
    );

    // Buat channel agar notifikasi (foreground & background) tampil benar.
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Minta izin notifikasi (Android 13+).
    await FirebaseMessaging.instance.requestPermission();

    // Saat app foreground, sistem tidak menampilkan otomatis → tampilkan manual.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tap notifikasi saat app di background → buka tab terkait.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _routeTo(m.data['type']));

    // Tap notifikasi saat app terminated (yang membuka app).
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _routeTo(initial.data['type']);

    // Token bisa berubah sewaktu-waktu → daftarkan ulang.
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendToken);
  }

  /// Set intent navigasi bila tipe reminder dikenali.
  void _routeTo(String? type) {
    if (type == 'food' || type == 'exercise') {
      reminderNavIntent.value = type;
    }
  }

  /// Ambil token FCM & kirim ke server. Panggil setelah user login.
  Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _sendToken(token);
    } catch (_) {}
  }

  Future<void> _sendToken(String token) async {
    try {
      await ApiClient.instance.post('/client/device-token', data: {
        'token': token,
        'platform': 'android',
      });
    } catch (_) {}
  }

  /// Hapus token dari server & perangkat (panggil saat logout).
  Future<void> deleteToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiClient.instance
            .delete('/client/device-token', data: {'token': token});
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _fln.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'calorimate_reminders_v3',
          'Pengingat CaloriMate',
          channelDescription: 'Notifikasi pengingat dari CaloriMate',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound('cm'),
        ),
      ),
      payload: message.data['type'] as String?,
    );
  }
}
