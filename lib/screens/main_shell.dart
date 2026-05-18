import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';
import 'diary_screen.dart';
import 'exercise_screen.dart';
import 'statistics_screen.dart';
import 'history_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    DiaryScreen(),
    ExerciseScreen(),
    StatisticsScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.menu_book_rounded, 'Diary'),
                _navItem(2, Icons.flash_on_rounded, 'Exercise'),
                _navItem(3, Icons.bar_chart_rounded, 'Statistik'),
                _navItem(4, Icons.history_rounded, 'Riwayat'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? AppColors.accentGold : AppColors.primaryGreen.withValues(alpha: 0.5)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.quicksand(
              fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? AppColors.accentGold : AppColors.primaryGreen.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}
