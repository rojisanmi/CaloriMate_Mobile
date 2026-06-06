import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class TrainerItemsScreen extends StatefulWidget {
  final int programId;
  final String programTitle;

  const TrainerItemsScreen({
    super.key,
    required this.programId,
    required this.programTitle,
  });

  @override
  State<TrainerItemsScreen> createState() => _TrainerItemsScreenState();
}

class _TrainerItemsScreenState extends State<TrainerItemsScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/trainer/programs/${widget.programId}/items');
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
        _items = list.map((e) => e as Map<String, dynamic>).toList();
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
        title: const Text('Hapus Item?'),
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
      await _api.delete('/items/$id');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  void _showForm([Map<String, dynamic>? item]) {
    final nameCtrl = TextEditingController(text: item?['exercise_name']?.toString() ?? '');
    final durationCtrl = TextEditingController(text: item?['duration_minutes']?.toString() ?? '');
    final caloriesCtrl = TextEditingController(text: item?['calories_burned']?.toString() ?? '');
    String intensity = item?['intensity_level']?.toString() ?? 'medium';
    final isEditing = item != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit Item Latihan' : 'Tambah Item Latihan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: CmColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Gerakan'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Durasi (menit)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Kalori Terbakar'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: intensity,
                  decoration: const InputDecoration(labelText: 'Intensitas'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Rendah')),
                    DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                    DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                  ],
                  onChanged: (v) => setSheetState(() => intensity = v!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final data = {
                      'exercise_name': nameCtrl.text.trim(),
                      'duration_minutes': int.tryParse(durationCtrl.text) ?? 0,
                      'calories_burned': int.tryParse(caloriesCtrl.text) ?? 0,
                      'intensity_level': intensity,
                    };
                    try {
                      if (isEditing) {
                        await _api.put('/items/${item['id']}', data: data);
                      } else {
                        await _api.post(
                          '/trainer/programs/${widget.programId}/items',
                          data: data,
                        );
                      }
                      if (mounted) Navigator.pop(ctx);
                      _load();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
                      }
                    }
                  },
                  child: Text(isEditing ? 'Simpan' : 'Tambah'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items — ${widget.programTitle}'),
        actions: [
          IconButton(
            onPressed: () => _showForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Item',
          ),
        ],
      ),
      body: CmBackground(
        child: RefreshIndicator(
          color: CmColors.primaryGreen,
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
              : _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.sports_gymnastics, size: 64, color: Colors.black26),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada item latihan.\nTap + untuk menambahkan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CmCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2EAD3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.sports_gymnastics,
                                      color: CmColors.primaryGreen, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['exercise_name']?.toString() ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        [
                                          if (item['duration_minutes'] != null)
                                            '${item['duration_minutes']} menit',
                                          if (item['intensity_level'] != null)
                                            item['intensity_level'].toString(),
                                          if (item['calories_burned'] != null)
                                            '${item['calories_burned']} kkal',
                                        ].join(' · '),
                                        style:
                                            TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      color: CmColors.primaryGreen, size: 20),
                                  onPressed: () => _showForm(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _delete(
                                      (item['id'] as num?)?.toInt() ?? 0),
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
