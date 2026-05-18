import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/exercise_service.dart';
import 'exercise_detail_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});
  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<dynamic> _programs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ExerciseService.getPrograms();
      if (mounted) setState(() { _programs = data; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  String _diffLabel(String? d) {
    final v = (d ?? '').toLowerCase();
    if (['low','rendah','beginner','pemula','mudah','easy'].contains(v)) return 'Mudah';
    if (['high','tinggi','advanced','lanjutan','hard','sulit'].contains(v)) return 'Sulit';
    return 'Sedang';
  }
  Color _diffColor(String? d) {
    final l = _diffLabel(d);
    if (l == 'Mudah') return const Color(0xFF15803D);
    if (l == 'Sulit') return const Color(0xFFB91C1C);
    return const Color(0xFFA16207);
  }
  Color _diffBg(String? d) {
    final l = _diffLabel(d);
    if (l == 'Mudah') return const Color(0xFFDCFCE7);
    if (l == 'Sulit') return const Color(0xFFFEE2E2);
    return const Color(0xFFFEF9C3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : RefreshIndicator(color: AppColors.primaryGreen, onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Banner
                  Container(
                    width: double.infinity, height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, Color(0xFF3D6628)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight),
                      boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Program Latihan', style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Pilih program yang sesuai dengan tujuan fitness kamu',
                          style: GoogleFonts.quicksand(fontSize: 13, color: Colors.white70)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_programs.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(children: [
                        Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.backgroundBeige, borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.flash_on_rounded, color: AppColors.primaryGreen.withValues(alpha: 0.4), size: 28)),
                        const SizedBox(height: 12),
                        Text('Belum ada program latihan', style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textGray)),
                      ])))
                  else ...[
                    Text('Semua Program', style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                    const SizedBox(height: 12),
                    ...(_programs.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ExerciseDetailScreen(programId: p['id']))).then((_) => _load()),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
                          child: Column(children: [
                            // Accent bar
                            Container(height: 4, decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.accentGold]))),
                            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(p['title'] ?? 'Program', style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _diffBg(p['difficulty']), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_diffLabel(p['difficulty']), style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.w700, color: _diffColor(p['difficulty']))),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(Icons.access_time_rounded, size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Text('${p['duration'] ?? '-'} menit', style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textGray)),
                                const SizedBox(width: 16),
                                Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Text('${p['type'] ?? '-'}', style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textGray)),
                              ]),
                              const SizedBox(height: 12),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('Lihat Detail', style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                                Container(width: 28, height: 28,
                                  decoration: BoxDecoration(color: AppColors.backgroundBeige, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.chevron_right, size: 18, color: AppColors.primaryGreen)),
                              ]),
                            ])),
                          ]),
                        ),
                      ),
                    ))),
                  ],
                ]),
              )),
      ),
    );
  }
}
