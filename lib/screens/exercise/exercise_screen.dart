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
  State<ExerciseScreen> createState() => ExerciseScreenState();
}

class ExerciseScreenState extends State<ExerciseScreen> {
  void reload() => _load();

  final _api = ApiClient.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _recommendations = [];

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
      _loadRecommendations();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final res = await _api.get('/client/recommendations/exercise');
      final data = res.data as Map<String, dynamic>;
      final recs = data['recommendations'] as List? ?? [];
      if (mounted) {
        setState(() {
          _recommendations = recs
              .map((e) => e as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (_) {}
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
                  // ── Rekomendasi Latihan ──────────────────────────────
                  if (_recommendations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: CmColors.accentOrange, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Rekomendasi Latihan Untukmu',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: CmColors.primaryGreen,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._recommendations.map((rec) {
                      final program = rec['program'] as Map<String, dynamic>? ?? {};
                      final tag = rec['tag']?.toString() ?? '';
                      final title = program['title']?.toString() ?? '';
                      final difficulty = program['difficulty']?.toString() ?? '';
                      final estCal = program['estimated_calories'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CmColors.accentOrange.withValues(alpha: 0.12),
                                Colors.white,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: CmColors.accentOrange.withValues(alpha: 0.3)),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final id = program['id'] as int?;
                              if (id == null) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExerciseDetailScreen(
                                    programId: id,
                                    title: title,
                                  ),
                                ),
                              );
                              _load();
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: CmColors.accentOrange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.local_fire_department,
                                      color: CmColors.accentOrange, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: CmColors.primaryGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '$difficulty · ~$estCal kkal',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: CmColors.accentOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: CmColors.accentOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
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
