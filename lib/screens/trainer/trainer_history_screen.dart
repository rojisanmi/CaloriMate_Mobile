import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class TrainerHistoryScreen extends StatefulWidget {
  const TrainerHistoryScreen({super.key});

  @override
  State<TrainerHistoryScreen> createState() => _TrainerHistoryScreenState();
}

class _TrainerHistoryScreenState extends State<TrainerHistoryScreen> {
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
      final res = await _api.get('/trainer/programs');
      final data = res.data;
      List list;
      if (data is Map<String, dynamic> && data['data'] is List) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Program'),
        automaticallyImplyLeading: false,
      ),
      body: CmBackground(
        child: RefreshIndicator(
          color: CmColors.primaryGreen,
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
              : _programs.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.history, size: 64, color: Colors.black26),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada program yang dibuat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _programs.length,
                      itemBuilder: (_, i) {
                        final p = _programs[i];
                        final createdAt = p['created_at']?.toString() ?? '';
                        final itemsCount = (p['items'] as List?)?.length ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CmCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: CmColors.accentOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.fitness_center,
                                      color: CmColors.accentOrange),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['title']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: CmColors.primaryGreen,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${p['type'] ?? ''} · ${p['difficulty'] ?? ''} · $itemsCount items',
                                        style:
                                            TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                      if (createdAt.isNotEmpty)
                                        Text(
                                          'Dibuat: ${_formatDate(createdAt)}',
                                          style: TextStyle(
                                              fontSize: 11, color: Colors.grey.shade400),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw;
    }
  }
}
