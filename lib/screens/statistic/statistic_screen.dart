import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => StatisticScreenState();
}

class StatisticScreenState extends State<StatisticScreen> {
  void reload() => _load();

  final _api = ApiClient.instance;
  bool _loading = true;
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _weeklyData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/client/statistic');
      final resWeekly = await _api.get('/client/recommendations/weekly');
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _weeklyData = resWeekly.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen));
    }

    final stat = _data?['statistik'] as Map<String, dynamic>? ?? {};
    final nutrition = _data?['nutrition'] as Map<String, dynamic>? ?? {};
    final foods = _data?['foods_today'] as List? ?? [];
    final aktivitas = _data?['aktivitas'] as List? ?? [];
    final date = _data?['date']?.toString() ?? '';

    final summaryItems = [
      ('Kalori Masuk', stat['kalori_masuk'], CmColors.accentOrange),
      ('Kalori Keluar', stat['kalori_keluar'], CmColors.primaryGreen),
      ('Selisih', stat['selisih'], CmColors.netCalories),
    ];

    final macros = [
      ('Protein', nutrition['protein'], const Color(0xFFDBEAFE), CmColors.protein),
      ('Karbo', nutrition['karbo'], const Color(0xFFDCFCE7), CmColors.carbs),
      ('Lemak', nutrition['lemak'], const Color(0xFFFFEDD5), CmColors.fat),
    ];

    return CmBackground(
      child: RefreshIndicator(
        color: CmColors.primaryGreen,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text('Statistik Harian', style: Theme.of(context).textTheme.headlineSmall),
            if (date.isNotEmpty)
              Text(
                _formatDate(date),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            const SizedBox(height: 16),
            Row(
              children: summaryItems.map((item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CmCard(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.$2 ?? 0}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: item.$3,
                            ),
                          ),
                          Text('kkal', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Nutrisi Hari Ini', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: _NutritionPieChart(nutrition: nutrition),
            ),
            const SizedBox(height: 12),
            Row(
              children: macros.map((m) {
                final val = _toDouble(m.$2) ?? 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.$3,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            m.$1,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: m.$4,
                            ),
                          ),
                          Text(
                            '${val.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: m.$4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Makanan Hari Ini', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (foods.isEmpty)
              CmCard(
                child: Text(
                  'Belum ada makanan tercatat',
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              )
            else
              CmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: foods.map((f) {
                    final food = f as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      title: Text(
                        food['nama']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${food['kategori']} · ${food['porsi']} porsi',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${food['kalori']?.toString() ?? 0} kkal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CmColors.primaryGreen,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            Text('Aktivitas Hari Ini', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (aktivitas.isEmpty)
              CmCard(
                child: Text(
                  'Belum ada aktivitas',
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...aktivitas.map((a) {
                final act = a as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CmCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_run, color: CmColors.accentOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act['nama']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${act['waktu_menit'] ?? 0} menit · ${act['kalori_terbakar'] ?? 0} kkal',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              
            if (_weeklyData != null && (_weeklyData!['tips'] as List?)?.isNotEmpty == true) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: CmColors.accentOrange, size: 22),
                  const SizedBox(width: 8),
                  Text('Saran Perbaikan Mingguan', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              CmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: ((_weeklyData!['tips'] as List?) ?? []).map((tip) {
                    final t = tip as Map<String, dynamic>;
                    final type = t['type']?.toString() ?? 'info';
                    final text = t['text']?.toString() ?? '';
                    
                    Color bColor = Colors.grey;
                    if (type == 'success') {
                      bColor = Colors.green;
                    } else if (type == 'danger') {
                      bColor = Colors.red;
                    } else if (type == 'warning') {
                      bColor = Colors.orange;
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: bColor, width: 4)),
                      ),
                      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
                      child: Text(
                        text,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(date).toLocal());
    } catch (_) {
      return date;
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class _NutritionPieChart extends StatelessWidget {
  final Map<String, dynamic> nutrition;

  const _NutritionPieChart({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final protein = _v(nutrition['protein']);
    final lemak = _v(nutrition['lemak']);
    final karbo = _v(nutrition['karbo']);
    final total = protein + lemak + karbo;

    if (total <= 0) {
      return const Center(child: Text('Belum ada data nutrisi'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: [
          _section(protein, CmColors.protein, 'Protein'),
          _section(lemak, CmColors.fat, 'Lemak'),
          _section(karbo, CmColors.carbs, 'Karbo'),
        ],
      ),
    );
  }

  double _v(dynamic x) {
    if (x is num) return x.toDouble();
    return double.tryParse(x?.toString() ?? '') ?? 0;
  }

  PieChartSectionData _section(double value, Color color, String title) {
    return PieChartSectionData(
      value: value > 0 ? value : 0.01,
      color: color,
      title: value > 0 ? '${value.round()}' : '',
      radius: 50,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
