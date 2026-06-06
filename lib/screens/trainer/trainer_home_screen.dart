import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class TrainerHomeScreen extends StatelessWidget {
  const TrainerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return CmBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo,',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
            ),
            Text(
              '${auth.displayName}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: CmColors.accentOrange,
                    fontSize: 28,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola program latihan untuk client kamu',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CmColors.primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.fitness_center, color: CmColors.accentOrange, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trainer Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Buat dan kelola program latihan terbaik',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Menu Cepat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CmColors.primaryGreen,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                _QuickLink(icon: Icons.fitness_center_outlined, label: 'Program'),
                _QuickLink(icon: Icons.list_alt_outlined, label: 'Items Latihan'),
                _QuickLink(icon: Icons.history_outlined, label: 'Riwayat'),
                _QuickLink(icon: Icons.person_outline, label: 'Profil'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickLink({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return CmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CmColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CmColors.primaryGreen, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: CmColors.primaryGreen,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
