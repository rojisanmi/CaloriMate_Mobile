import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/trainer/trainer_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
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
