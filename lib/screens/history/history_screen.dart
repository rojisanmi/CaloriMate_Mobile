import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  void reload() => _load();

  final _api = ApiClient.instance;
  bool _loading = true;
  String _period = 'daily';
  Map<String, dynamic>? _data;

  static const _periods = {
    'daily': 'Harian (7 hari)',
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    '1_day': 'Hari ini',
    '7_days': '7 hari',
    '1_month': '1 bulan',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/client/history', query: {'period': _period});
      setState(() {
        _data = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CmBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Riwayat', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _periods.entries.map((e) {
                      final selected = _period == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(e.value, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _period = e.key);
                            _load();
                          },
                          selectedColor: CmColors.accentOrange.withValues(alpha: 0.4),
                          checkmarkColor: CmColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: selected ? CmColors.primaryGreen : Colors.grey.shade700,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
                : RefreshIndicator(
                    color: CmColors.primaryGreen,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_data != null) ...[
                          _ChartSection(data: _data!),
                          const SizedBox(height: 16),
                          Text('Riwayat Makanan', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _HistoryList(
                            items: _data!['histories'] as List? ?? [],
                            emptyAsset: 'assets/images/empty/empty-history.png',
                            emptyText: 'Belum ada riwayat makanan',
                          ),
                          const SizedBox(height: 16),
                          Text('Aktivitas', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _ActivityList(activities: _data!['activities'] as List? ?? []),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ChartSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final chart = data['chart_data'] as Map<String, dynamic>? ?? {};
    final labels = (chart['labels'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final calIn = (chart['calori_in'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final calOut = (chart['calori_out'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];

    if (labels.isEmpty) {
      return CmCard(
        child: Text(
          'Belum ada data grafik',
          style: TextStyle(color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      );
    }

    final maxY = [...calIn, ...calOut].fold<double>(0, (a, b) => a > b ? a : b) * 1.2;

    return CmCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Kalori',
            style: TextStyle(fontWeight: FontWeight.bold, color: CmColors.primaryGreen),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY > 0 ? maxY : 100,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= 0 && i < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[i],
                              style: const TextStyle(fontSize: 9),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(labels.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: i < calIn.length ? calIn[i] : 0,
                        color: CmColors.accentOrange,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: i < calOut.length ? calOut[i] : 0,
                        color: CmColors.primaryGreen,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(CmColors.accentOrange, 'Kalori Masuk'),
              const SizedBox(width: 16),
              _legend(CmColors.primaryGreen, 'Kalori Keluar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

String _formatDate(dynamic raw) {
  final s = raw?.toString() ?? '';
  if (s.isEmpty) return '';
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  final local = dt.toLocal();
  // Tampilkan jam hanya jika bukan tengah malam
  final pattern = (local.hour == 0 && local.minute == 0)
      ? 'd MMM yyyy'
      : 'd MMM yyyy, HH:mm';
  return DateFormat(pattern, 'id_ID').format(local);
}

class _HistoryList extends StatelessWidget {
  final List items;
  final String emptyAsset;
  final String emptyText;

  const _HistoryList({
    required this.items,
    required this.emptyAsset,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return CmCard(
        child: Column(
          children: [
            Image.asset(emptyAsset, height: 80, errorBuilder: (_, _, _) =>
                Icon(Icons.history, size: 64, color: Colors.grey.shade300)),
            const SizedBox(height: 8),
            Text(emptyText, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return CmCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.map((item) {
          final m = item as Map<String, dynamic>;
          return ListTile(
            dense: true,
            title: Text(m['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              m['portions'] != null
                  ? '${m['portions']} porsi · ${_formatDate(m['date'])}'
                  : _formatDate(m['date']),
            ),
            trailing: Text(
              '${m['calories'] ?? 0} kkal',
              style: const TextStyle(fontWeight: FontWeight.bold, color: CmColors.primaryGreen),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List activities;

  const _ActivityList({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return CmCard(
        child: Text(
          'Belum ada aktivitas',
          style: TextStyle(color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      );
    }

    return CmCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: activities.map((a) {
          final m = a as Map<String, dynamic>;
          return ListTile(
            dense: true,
            leading: const Icon(Icons.fitness_center, color: CmColors.accentOrange, size: 20),
            title: Text(m['program_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(_formatDate(m['date'])),
            trailing: Text(
              '${m['calories_out'] ?? 0} kkal',
              style: const TextStyle(fontWeight: FontWeight.bold, color: CmColors.primaryGreen, fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }
}
