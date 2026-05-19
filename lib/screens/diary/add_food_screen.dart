import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class AddFoodScreen extends StatefulWidget {
  final String category;
  final String categoryLabel;

  const AddFoodScreen({
    super.key,
    required this.category,
    required this.categoryLabel,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _api = ApiClient.instance;
  final _search = TextEditingController();
  final _portions = TextEditingController(text: '1');

  List<Map<String, dynamic>> _foods = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  @override
  void dispose() {
    _search.dispose();
    _portions.dispose();
    super.dispose();
  }

  Future<void> _loadFoods({String? q}) async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/client/foods', query: q != null ? {'q': q} : null);
      final list = res.data as List;
      setState(() {
        _foods = list.map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih makanan terlebih dahulu')),
      );
      return;
    }
    final portions = int.tryParse(_portions.text) ?? 1;
    setState(() => _saving = true);
    try {
      await _api.post('/client/diary', data: {
        'food_id': _selected!['food_id'],
        'portions': portions,
        'category': widget.category,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Makanan berhasil ditambahkan'),
            backgroundColor: CmColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tambah — ${widget.categoryLabel}')),
      body: CmBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Cari makanan...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      _loadFoods();
                    },
                  ),
                ),
                onSubmitted: (v) => _loadFoods(q: v.isEmpty ? null : v),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _foods.length,
                      itemBuilder: (_, i) {
                        final food = _foods[i];
                        final selected = _selected?['food_id'] == food['food_id'];
                        final cal = food['calories_per_portion'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: selected
                              ? CmColors.primaryGreen.withValues(alpha: 0.08)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: selected ? CmColors.primaryGreen : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              food['name']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${cal ?? 0} kkal/porsi'),
                            trailing: selected
                                ? const Icon(Icons.check_circle, color: CmColors.primaryGreen)
                                : null,
                            onTap: () => setState(() => _selected = food),
                          ),
                        );
                      },
                    ),
            ),
            CmCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _portions,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah Porsi'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CmColors.primaryGreen,
                            side: const BorderSide(color: CmColors.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
