import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'trainer_dashboard_screen.dart';
import 'trainer_foods_screen.dart';
import 'trainer_programs_screen.dart';
import '../profile/trainer_profile_screen.dart';

class TrainerShell extends StatefulWidget {
  const TrainerShell({super.key});

  @override
  State<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends State<TrainerShell> {
  int _index = 0;

  final _screens = const [
    TrainerDashboardScreen(),
    TrainerFoodsScreen(),
    TrainerProgramsScreen(),
    TrainerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isActive: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.restaurant_menu_outlined,
                  activeIcon: Icons.restaurant_menu,
                  label: 'Makanan',
                  isActive: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.fitness_center_outlined,
                  activeIcon: Icons.fitness_center,
                  label: 'Latihan',
                  isActive: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  isActive: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? CmColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? CmColors.primaryGreen : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? CmColors.primaryGreen : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
