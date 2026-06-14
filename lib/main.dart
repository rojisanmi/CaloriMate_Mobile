import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/trainer/trainer_shell.dart';
import 'services/notification_service.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService.instance.init();
  // Reminder ditangani push FCM; pastikan tidak ada alarm lokal lama yang
  // masih terjadwal (mencegah notif dobel pada perangkat yang sudah terlanjur).
  await NotificationService.instance.cancelLocalReminders();

  // Firebase Cloud Messaging (push notification)
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CaloriMateApp());
}

class CaloriMateApp extends StatelessWidget {
  const CaloriMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'CaloriMate',
        debugShowCheckedModeBanner: false,
        theme: CmTheme.light,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        backgroundColor: CmColors.backgroundCream,
        body: Center(
          child: CircularProgressIndicator(color: CmColors.primaryGreen),
        ),
      );
    }

    if (!auth.isLoggedIn) return const LoginScreen();

    // Route by role
    if (auth.isTrainer) return const TrainerShell();
    return const MainShell();
  }
}
