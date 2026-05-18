import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _period = 'daily';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await HistoryService.getHistory(period: _period);
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        : RefreshIndicator(color: AppColors.primaryGreen, onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Riwayat Aktivitas', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                Text('Pantau pola kalori dan latihan kamu', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textGray)),
                const SizedBox(height: 16),
                _periodSelector(),
                const SizedBox(height: 16),
                _chartCard(),
                const SizedBox(height: 16),
                _activitiesSection(),
                const SizedBox(height: 16),
                _historiesSection(),
              ])))),
    );
  }

  Widget _periodSelector() {
    final options = [
      {'key': 'daily', 'label': '7 Hari'},
      {'key': 'weekly', 'label': 'Mingguan'},
      {'key': 'monthly', 'label': 'Bulanan'},
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Row(children: options.map((o) {
        final active = _period == o['key'];
        return Expanded(child: GestureDetector(
          onTap: () { _period = o['key']!; _load(); },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(o['label']!, style: GoogleFonts.quicksand(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textGray))),
          ),
        ));
      }).toList()),
    );
  }

  Widget _chartCard() {
    final chart = _data?['chart_data'] as Map<String, dynamic>? ?? {};
    final labels = (chart['labels'] as List<dynamic>? ?? []).map((e) => e?.toString() ?? '').toList();
    final calIn = (chart['calori_in'] as List<dynamic>? ?? []).map((e) => double.tryParse(e?.toString() ?? '') ?? 0.0).toList();
    final calOut = (chart['calori_out'] as List<dynamic>? ?? []).map((e) => double.tryParse(e?.toString() ?? '') ?? 0.0).toList();


    if (labels.isEmpty) {
      return Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('Belum ada data', style: GoogleFonts.quicksand(color: AppColors.textLightGray))));
    }

    double maxVal = 0;
    for (var v in calIn) { if (v > maxVal) maxVal = v; }
    for (var v in calOut) { if (v > maxVal) maxVal = v; }
    if (maxVal == 0) maxVal = 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Kalori Masuk & Keluar', style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
        const SizedBox(height: 8),
        Row(children: [
          _legendDot(AppColors.accentGold, 'Masuk'),
          const SizedBox(width: 16),
          _legendDot(AppColors.primaryGreen, 'Keluar'),
        ]),
        const SizedBox(height: 12),
        SizedBox(height: 160, child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(labels.length, (i) {
            final inH = (calIn.length > i ? calIn[i] : 0) / maxVal * 120;
            final outH = (calOut.length > i ? calOut[i] : 0) / maxVal * 120;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(width: 8, height: inH.clamp(2, 120),
                    decoration: BoxDecoration(color: AppColors.accentGold, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 2),
                  Container(width: 8, height: outH.clamp(2, 120),
                    decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(3))),
                ]),
                const SizedBox(height: 6),
                Text(labels[i].length > 5 ? labels[i].substring(0, 5) : labels[i],
                  style: GoogleFonts.quicksand(fontSize: 8, color: AppColors.textLightGray), overflow: TextOverflow.ellipsis),
              ]),
            ));
          }),
        )),
      ]),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textGray)),
    ]);
  }

  Widget _activitiesSection() {
    final acts = _data?['activities'] as List<dynamic>? ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Aktivitas Latihan', style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
      const SizedBox(height: 10),
      if (acts.isEmpty) Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('Belum ada aktivitas', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textLightGray))))
      else ...acts.map((a) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['program_name'] ?? '', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
            Text(a['date'] ?? '', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Kalori Keluar', style: GoogleFonts.quicksand(fontSize: 10, color: AppColors.textLightGray)),
            Text('${a['calories_out'] ?? 0} kkal', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
          ]),
        ]),
      ))),
    ]);
  }

  Widget _historiesSection() {
    final hist = _data?['histories'] as List<dynamic>? ?? [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Riwayat Konsumsi', style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
      const SizedBox(height: 10),
      if (hist.isEmpty) Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('Tidak ada riwayat', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textLightGray))))
      else ...hist.take(20).map((h) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h['name'] ?? '', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
            Text(h['date'] ?? '', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Kalori Masuk', style: GoogleFonts.quicksand(fontSize: 10, color: AppColors.textLightGray)),
            Text('${h['calories'] ?? 0} kkal', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
          ]),
        ]),
      ))),
    ]);
  }
}
