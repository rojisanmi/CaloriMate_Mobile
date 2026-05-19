import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
import 'exercise_detail_screen.dart';
import '../maps/maps_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/client/exercise');
      final list = res.data as List;
      setState(() {
        _programs = list.map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CmBackground(
      child: RefreshIndicator(
        color: CmColors.primaryGreen,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/exercise-banner.jpeg',
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CmColors.primaryGreen.withValues(alpha: 0.9),
                                CmColors.primaryGreen.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 20,
                          top: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Program Latihan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pilih program sesuai tujuan fitness kamu',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Button to find nearby gyms and parks
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapsScreen(mode: 'exercise'),
                        ),
                      ),
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Temukan Gym / Taman Terdekat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CmColors.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_programs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Belum ada program latihan',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    ..._programs.map((p) => _ProgramCard(
                          program: p,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExerciseDetailScreen(
                                  programId: p['id'] as int,
                                  title: p['title']?.toString() ?? 'Program',
                                ),
                              ),
                            );
                            _load();
                          },
                        )),
                ],
              ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final Map<String, dynamic> program;
  final VoidCallback onTap;

  const _ProgramCard({required this.program, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final diff = program['difficulty']?.toString() ?? '';
    final diffStyle = _difficultyStyle(diff);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CmCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: CmColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: CmColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program['title']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CmColors.primaryGreen,
                          fontSize: 15,
                        ),
                      ),
                      if (program['type'] != null)
                        Text(
                          program['type'].toString(),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffStyle.$1,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    diffStyle.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: diffStyle.$3,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: CmColors.primaryGreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, String, Color) _difficultyStyle(String diff) {
    final d = diff.toLowerCase();
    if (['low', 'rendah', 'beginner', 'pemula', 'mudah', 'easy'].any(d.contains)) {
      return (const Color(0xFFDCFCE7), 'Mudah', const Color(0xFF15803D));
    }
    if (['high', 'tinggi', 'advanced', 'lanjutan', 'hard', 'sulit'].any(d.contains)) {
      return (const Color(0xFFFEE2E2), 'Sulit', const Color(0xFFB91C1C));
    }
    return (const Color(0xFFFEF9C3), 'Sedang', const Color(0xFFA16207));
  }
}
