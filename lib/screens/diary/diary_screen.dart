import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
import '../../widgets/cm_progress_bar.dart';
import 'add_food_screen.dart';
import '../maps/maps_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  Map<String, dynamic>? _data;

  static const _categories = {
    'breakfast': ('Sarapan', 'assets/images/categories/icon-breakfast.png'),
    'lunch': ('Makan Siang', 'assets/images/categories/icon-lunch.png'),
    'dinner': ('Makan Malam', 'assets/images/categories/icon-dinner.png'),
    'snack': ('Camilan', 'assets/images/categories/icon-snack.png'),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/client/diary');
      if (mounted) {
        setState(() {
          _data = _parseDiaryResponse(res.data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Normalises API response — consumptions may be `{}`, `[]`, or grouped map.
  Map<String, dynamic>? _parseDiaryResponse(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map['consumptions'] = _normalizeConsumptions(map['consumptions']);
      return map;
    }
    if (raw is List) {
      return {
        'daily_target': null,
        'consumed_calories': null,
        'remaining_calories': null,
        'consumptions': _normalizeConsumptions(raw),
      };
    }
    return null;
  }

  Map<String, List<dynamic>> _normalizeConsumptions(dynamic cons) {
    if (cons is Map) {
      return cons.map((k, v) {
        if (v is List) return MapEntry(k.toString(), List<dynamic>.from(v));
        if (v is Map) return MapEntry(k.toString(), <dynamic>[v]);
        return MapEntry(k.toString(), <dynamic>[]);
      });
    }
    if (cons is List) {
      final grouped = <String, List<dynamic>>{};
      for (final el in cons) {
        if (el is Map && el['category'] != null) {
          final cat = el['category'].toString();
          grouped.putIfAbsent(cat, () => []).add(el);
        }
      }
      return grouped;
    }
    return {};
  }

  Future<void> _remove(int foodId, String category) async {
    try {
      await _api.delete('/client/diary', data: {
        'food_id': foodId,
        'category': category,
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen));
    }

    final target = _toDouble(_data?['daily_target']) ?? 2000;
    final consumed = _toDouble(_data?['consumed_calories']) ?? 0;
    final remaining = _toDouble(_data?['remaining_calories']) ?? 0;
    final pct = target > 0 ? (consumed / target * 100).clamp(0.0, 100.0) : 0.0;
    final consumptions = _data?['consumptions'] is Map
        ? Map<String, dynamic>.from(_data!['consumptions'] as Map)
        : <String, dynamic>{};

    return CmBackground(
      child: RefreshIndicator(
        color: CmColors.primaryGreen,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diary Hari Ini', style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        'Catat makanan yang kamu konsumsi hari ini',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapsScreen(mode: 'restaurant'),
                    ),
                  ),
                  icon: const Icon(Icons.restaurant_outlined, size: 16),
                  label: const Text('Restoran', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CmColors.primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KONSUMSI KALORI',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: '${consumed.round()}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${target.round()} kkal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SISA',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${remaining.round()}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: CmColors.accentOrange,
                            ),
                          ),
                          Text(
                            'kkal',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CmProgressBar(
                    percent: pct,
                    color: CmColors.accentOrange,
                    trackColor: Colors.white.withValues(alpha: 0.2),
                    height: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._categories.entries.map((e) {
              final items = consumptions[e.key] as List? ?? [];
              return _MealSection(
                key: ValueKey(e.key),
                category: e.key,
                label: e.value.$1,
                iconPath: e.value.$2,
                items: items,
                onAdd: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddFoodScreen(category: e.key, categoryLabel: e.value.$1),
                    ),
                  );
                  _load();
                },
                onRemove: (foodId) => _remove(foodId, e.key),
              );
            }),
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

class _MealSection extends StatelessWidget {
  final String category;
  final String label;
  final String iconPath;
  final List items;
  final VoidCallback onAdd;
  final void Function(int foodId) onRemove;

  const _MealSection({
    super.key,
    required this.category,
    required this.label,
    required this.iconPath,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    var totalCal = 0.0;
    for (final item in items) {
      final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final food = m['food'] is Map ? Map<String, dynamic>.from(m['food'] as Map) : <String, dynamic>{};
      final portions = (m['portions'] as num?)?.toDouble() ?? 1;
      final cal = _toDouble(food['calories_per_portion']) ?? 0;
      totalCal += cal * portions;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(iconPath, width: 28, height: 28, errorBuilder: (_, __, ___) =>
                    Icon(Icons.restaurant, color: CmColors.primaryGreen, size: 28)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.titleMedium),
                ),
                Text(
                  '${totalCal.round()} kkal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CmColors.accentOrange,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Makanan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Belum ada makanan',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              )
            else
              ...items.map((item) {
                final m = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                final food = m['food'] is Map ? Map<String, dynamic>.from(m['food'] as Map) : <String, dynamic>{};
                final portions = (m['portions'] as num?)?.toInt() ?? 1;
                final foodId = (food['food_id'] as num?)?.toInt() ?? (m['food_id'] as num?)?.toInt() ?? 0;
                final cal = (_toDouble(food['calories_per_portion']) ?? 0) * portions;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    food['name']?.toString() ?? 'Makanan',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text('$portions porsi · ${cal.round()} kkal',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => onRemove(foodId),
                  ),
                );
              }),
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
