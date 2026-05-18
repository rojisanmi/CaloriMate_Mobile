import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/exercise_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int programId;
  const ExerciseDetailScreen({super.key, required this.programId});
  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  Map<String, dynamic>? _program;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ExerciseService.getProgramDetail(widget.programId);
      if (mounted) setState(() { _program = data; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _startProgram() async {
    setState(() => _starting = true);
    try {
      final result = await ExerciseService.startProgram(widget.programId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Program dimulai!'),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      setState(() => _starting = false);
    } catch (e) {
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(title: Text(_program?['name'] ?? 'Detail Program'), backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Program info card
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_program?['name'] ?? 'Program', style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Row(children: [
                  _infoPill(Icons.access_time_rounded, '${_program?['duration_minutes'] ?? '-'} menit'),
                  const SizedBox(width: 12),
                  _infoPill(Icons.local_fire_department_rounded, _program?['difficulty'] ?? '-'),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            Text('Daftar Latihan', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
            const SizedBox(height: 12),

            // Exercise items
            ...(_program?['items'] as List<dynamic>? ?? []).asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text('${i + 1}', style: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.accentGold)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['exercise_name'] ?? 'Latihan', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text('${item['duration_minutes'] ?? '-'} menit', style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textGray)),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.backgroundBeige, borderRadius: BorderRadius.circular(6)),
                        child: Text(item['intensity_level'] ?? '-', style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryGreen))),
                    ]),
                  ])),
                  if (item['sets'] != null) Text('${item['sets']}x${item['reps'] ?? '-'}', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGray)),
                ]),
              ));
            }),

            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
              onPressed: _starting ? null : _startProgram,
              icon: _starting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(_starting ? 'Memulai...' : 'Mulai Latihan', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
            )),
          ])),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.accentGold),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      ]));
  }
}
