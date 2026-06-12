import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/bmi.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
import '../../widgets/cm_progress_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final client = auth.client;
    final bb = _toDouble(client?['bb']);
    final tb = _toDouble(client?['tb']);
    final bmiInfo = calculateBmi(bb, tb);

    return CmBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo,',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                  ),
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
              'Siap pantau kalori hari ini?',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (bmiInfo != null) _BmiCard(info: bmiInfo, bb: bb!, tb: tb!) else _BmiPlaceholder(),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CmColors.accentOrange.withValues(alpha: 0.1),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/dashboard-hero.jpeg',
                      width: 220,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class _BmiCard extends StatelessWidget {
  final BmiInfo info;
  final double bb;
  final double tb;

  const _BmiCard({required this.info, required this.bb, required this.tb});

  @override
  Widget build(BuildContext context) {
    final pct = ((info.bmi - 10) / 30 * 100).clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(info.bgColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${info.bmi}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Color(info.textColor),
                  height: 1,
                ),
              ),
              Text(
                info.category,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(info.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BODY MASS INDEX',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(info.textColor).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 8),
                CmProgressBar(
                  percent: pct,
                  color: Color(info.barColor),
                  trackColor: Colors.black.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 6),
                Text(
                  '$bb kg · $tb cm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(info.textColor).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CmCard(
      child: Row(
        children: [
          Icon(Icons.info_outline, color: CmColors.accentOrange, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI belum tersedia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Lengkapi profil kamu',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
