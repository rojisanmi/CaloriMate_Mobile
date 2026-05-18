import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/diary_service.dart';
import 'add_food_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});
  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await DiaryService.getDiary();
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
                  Text('Diary Hari Ini', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                  Text('Catat makanan yang kamu konsumsi hari ini', style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  _calorieCard(),
                  const SizedBox(height: 12),
                  _macroCard(),
                  const SizedBox(height: 20),
                  ..._mealSegments(),
                ]),
              )),
      ),
    );
  }

  Widget _calorieCard() {
    final target = double.tryParse(_data?['daily_target']?.toString() ?? '') ?? 2000.0;
    final consumed = double.tryParse(_data?['consumed_calories']?.toString() ?? '') ?? 0.0;
    final remaining = double.tryParse(_data?['remaining_calories']?.toString() ?? '') ?? target;
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('KONSUMSI KALORI', style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white60)),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: '${consumed.round()}', style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
              TextSpan(text: ' / ${target.round()} kkal', style: GoogleFonts.quicksand(fontSize: 14, color: Colors.white60)),
            ])),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('SISA', style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white60)),
            Text('${remaining.round()}', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.accentGold)),
            Text('kkal', style: GoogleFonts.quicksand(fontSize: 11, color: Colors.white38)),
          ]),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: Colors.white24, color: AppColors.accentGold)),
      ]),
    );
  }

  Widget _macroCard() {
    // We estimate macros from consumptions if available
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('TARGET MAKRO', style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.textLightGray)),
        const SizedBox(height: 10),
        _macroRow('Protein', AppColors.proteinBlue, 0.4),
        const SizedBox(height: 8),
        _macroRow('Karbo', AppColors.carboGreen, 0.5),
        const SizedBox(height: 8),
        _macroRow('Lemak', AppColors.fatOrange, 0.3),
      ]),
    );
  }

  Widget _macroRow(String label, Color color, double pct) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        Text('—', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.grey.shade100, color: color)),
    ]);
  }

  List<Widget> _mealSegments() {
    final categories = [
      {'label': 'Makan Pagi', 'key': 'breakfast', 'icon': Icons.wb_sunny_rounded},
      {'label': 'Makan Siang', 'key': 'lunch', 'icon': Icons.wb_cloudy_rounded},
      {'label': 'Makan Malam', 'key': 'dinner', 'icon': Icons.nights_stay_rounded},
      {'label': 'Camilan', 'key': 'snack', 'icon': Icons.cookie_rounded},
    ];
    final rawConsumptions = _data?['consumptions'];
    final Map<String, dynamic> consumptions = {};
    if (rawConsumptions is Map) {
      rawConsumptions.forEach((key, value) {
        consumptions[key.toString()] = value;
      });
    }
    return categories.map((cat) {
      final foods = consumptions[cat['key']] as List<dynamic>? ?? [];
      double totalCal = 0;
      for (var f in foods) {
        final calPerPortion = double.tryParse(f['food']?['calories_per_portion']?.toString() ?? '') ?? 0.0;
        final portions = double.tryParse(f['portions']?.toString() ?? '') ?? 1.0;
        totalCal += calPerPortion * portions;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), child: Column(children: [
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.backgroundBeige, borderRadius: BorderRadius.circular(12)),
                  child: Icon(cat['icon'] as IconData, color: AppColors.primaryGreen, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat['label'] as String, style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                  Text('${foods.length} item · ${totalCal.round()} kkal', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
                ])),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, height: 46, child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AddFoodScreen(category: cat['key'] as String)));
                  _load();
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('Tambah Makanan', style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              )),
            ])),
            if (foods.isNotEmpty) ...[
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              Padding(padding: const EdgeInsets.all(16), child: Column(
                children: foods.map<Widget>((f) {
                  final name = f['food']?['name'] ?? 'Makanan';
                  final calPerPortion = double.tryParse(f['food']?['calories_per_portion']?.toString() ?? '') ?? 0.0;
                  final portionsVal = double.tryParse(f['portions']?.toString() ?? '') ?? 1.0;
                  final cal = (calPerPortion * portionsVal).round();
                  final portions = f['portions'] ?? 1;
                  return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                      Text('$portions porsi', style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
                    ])),
                    Text('$cal kkal', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accentGold)),
                  ]));
                }).toList(),
              )),
            ] else
              Padding(padding: const EdgeInsets.all(20),
                child: Text('Belum ada makanan', style: GoogleFonts.quicksand(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textLightGray))),
          ]),
        ),
      );
    }).toList();
  }
}
