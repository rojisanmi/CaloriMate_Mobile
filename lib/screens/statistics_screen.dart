import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/statistic_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await StatisticService.getStatistics();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
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
                  Text('Statistik Harian', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                  Text(_data?['date'] ?? '', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  _summaryCards(),
                  const SizedBox(height: 16),
                  _nutritionCard(),
                  const SizedBox(height: 16),
                  _foodsTable(),
                  const SizedBox(height: 16),
                  _activitiesTable(),
                ]),
              )),
      ),
    );
  }

  Widget _summaryCards() {
    final s = _data?['statistik'] ?? {};
    final items = [
      {'label': 'Kalori Masuk', 'value': s['kalori_masuk'] ?? 0, 'color': AppColors.accentGold},
      {'label': 'Kalori Keluar', 'value': s['kalori_keluar'] ?? 0, 'color': AppColors.primaryGreen},
      {'label': 'Selisih', 'value': s['selisih'] ?? 0, 'color': AppColors.proteinBlue},
    ];
    return Row(children: items.map((item) => Expanded(child: Padding(
      padding: EdgeInsets.only(right: item != items.last ? 8 : 0),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Column(children: [
          Text((item['label'] as String).toUpperCase(), style: GoogleFonts.quicksand(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppColors.textLightGray)),
          const SizedBox(height: 6),
          Text(item['value'].toString(), style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: item['color'] as Color)),
          Text('kkal', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
        ])),
    ))).toList());
  }

  Widget _nutritionCard() {
    final n = _data?['nutrition'] ?? {};
    final macros = [
      {'label': 'Protein', 'val': n['protein'] ?? 0, 'color': AppColors.proteinBlue, 'bg': const Color(0xFFDBEAFE)},
      {'label': 'Karbo', 'val': n['karbo'] ?? 0, 'color': AppColors.carboGreen, 'bg': const Color(0xFFDCFCE7)},
      {'label': 'Lemak', 'val': n['lemak'] ?? 0, 'color': AppColors.fatOrange, 'bg': const Color(0xFFFFEDD5)},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Nutrisi Harian', style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
      const SizedBox(height: 10),
      Row(children: macros.map((m) => Expanded(child: Padding(
        padding: EdgeInsets.only(right: m != macros.last ? 8 : 0),
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: m['bg'] as Color, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text((m['label'] as String).toUpperCase(), style: GoogleFonts.quicksand(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: m['color'] as Color)),
            const SizedBox(height: 6),
            RichText(text: TextSpan(children: [
              TextSpan(text: '${(m['val'] as num).toStringAsFixed(1)}', style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w800, color: m['color'] as Color)),
              TextSpan(text: 'g', style: GoogleFonts.quicksand(fontSize: 12, color: m['color'] as Color)),
            ])),
          ])),
      ))).toList()),
    ]);
  }

  Widget _foodsTable() {
    final foods = _data?['foods_today'] as List<dynamic>? ?? [];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text('Riwayat Makanan', style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
        ])),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        if (foods.isEmpty) Padding(padding: const EdgeInsets.all(24),
          child: Text('Belum ada makanan dicatat', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textLightGray)))
        else ...foods.map((f) {
          final cal = double.tryParse(f['kalori']?.toString() ?? '') ?? 0.0;
          final prot = double.tryParse(f['protein']?.toString() ?? '') ?? 0.0;
          final lemak = double.tryParse(f['lemak']?.toString() ?? '') ?? 0.0;
          final karbo = double.tryParse(f['karbo']?.toString() ?? '') ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['nama'] ?? '', style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text('${f['kategori'] ?? ''} · ${f['porsi'] ?? 1} porsi', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${cal.round()} kkal', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                Text('P:${prot.toStringAsFixed(1)} L:${lemak.toStringAsFixed(1)} K:${karbo.toStringAsFixed(1)}',
                  style: GoogleFonts.quicksand(fontSize: 10, color: AppColors.textLightGray)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _activitiesTable() {
    final acts = _data?['aktivitas'] as List<dynamic>? ?? [];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text('Aktivitas Hari Ini', style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
        ])),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        if (acts.isEmpty) Padding(padding: const EdgeInsets.all(24),
          child: Text('Tidak ada aktivitas', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textLightGray)))
        else ...acts.map((a) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['nama'] ?? '', style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              Text('${a['waktu_menit'] ?? '-'} menit', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
            ])),
            Text('${a['kalori_terbakar'] ?? 0} kkal', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
          ]),
        )),
      ]),
    );
  }
}
