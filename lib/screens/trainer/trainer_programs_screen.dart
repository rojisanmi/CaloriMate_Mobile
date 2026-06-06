import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
import 'trainer_program_form_screen.dart';
import 'trainer_items_screen.dart';

class TrainerProgramsScreen extends StatefulWidget {
  const TrainerProgramsScreen({super.key});

  @override
  State<TrainerProgramsScreen> createState() => _TrainerProgramsScreenState();
}

class _TrainerProgramsScreenState extends State<TrainerProgramsScreen> {
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

  Future<void> _delete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Program?'),
        content: const Text('Program ini akan dihapus beserta semua items-nya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.delete('/trainer/programs/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program dihapus'), backgroundColor: CmColors.primaryGreen),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Latihan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainerProgramFormScreen()),
              );
              _load();
            },
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Program',
          ),
        ],
      ),
      body: CmBackground(
        child: RefreshIndicator(
          color: CmColors.primaryGreen,
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
              : _programs.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        const Icon(Icons.fitness_center, size: 64, color: Colors.black26),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada program latihan.\nTap + untuk membuat baru.',
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
                        final id = (p['id'] as num?)?.toInt() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CmCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: CmColors.primaryGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.fitness_center,
                                          color: CmColors.primaryGreen),
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
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (p['type'] != null)
                                            Text(
                                              '${p['type']} · ${p['difficulty'] ?? ''}',
                                              style: TextStyle(
                                                  fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  TrainerProgramFormScreen(program: p),
                                            ),
                                          );
                                          _load();
                                        } else if (val == 'items') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => TrainerItemsScreen(
                                                programId: id,
                                                programTitle: p['title']?.toString() ?? 'Program',
                                              ),
                                            ),
                                          );
                                        } else if (val == 'delete') {
                                          _delete(id);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'items', child: Text('Kelola Items')),
                                        PopupMenuItem(value: 'edit', child: Text('Edit Program')),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Hapus',
                                              style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TrainerItemsScreen(
                                              programId: id,
                                              programTitle:
                                                  p['title']?.toString() ?? 'Program',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.list, size: 16),
                                      label: const Text('Items',
                                          style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        foregroundColor: CmColors.primaryGreen,
                                        side: const BorderSide(
                                            color: CmColors.primaryGreen),
                                      ),
                                    ),
                                  ],
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
}
