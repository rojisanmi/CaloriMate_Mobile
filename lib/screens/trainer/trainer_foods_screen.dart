import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class TrainerFoodsScreen extends StatefulWidget {
  const TrainerFoodsScreen({super.key});

  @override
  State<TrainerFoodsScreen> createState() => _TrainerFoodsScreenState();
}

class _TrainerFoodsScreenState extends State<TrainerFoodsScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _foods = [];
  int _currentPage = 1;
  int _lastPage = 1;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final query = <String, dynamic>{'per_page': 20, 'page': page};
      if (_searchQuery.isNotEmpty) query['q'] = _searchQuery;

      final res = await _api.get('/trainer/foods', query: query);
      final data = res.data;

      List list;
      if (data is Map<String, dynamic>) {
        list = (data['data'] as List?) ?? [];
        _currentPage = (data['current_page'] as num?)?.toInt() ?? 1;
        _lastPage = (data['last_page'] as num?)?.toInt() ?? 1;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }

      setState(() {
        _foods = list.map((e) => e as Map<String, dynamic>).toList();
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
        title: const Text('Hapus Makanan?'),
        content: const Text('Data makanan ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _api.delete('/trainer/foods/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Makanan dihapus'),
              backgroundColor: CmColors.primaryGreen),
        );
      }
      _load(page: _currentPage);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  void _showForm([Map<String, dynamic>? food]) {
    final nameCtrl =
        TextEditingController(text: food?['name']?.toString() ?? '');
    final grammageCtrl =
        TextEditingController(text: food?['grammage']?.toString() ?? '');
    final caloriesCtrl = TextEditingController(
        text: food?['calories_per_portion']?.toString() ?? '');
    final fatCtrl =
        TextEditingController(text: food?['total_fat']?.toString() ?? '');
    final carboCtrl =
        TextEditingController(text: food?['total_carbo']?.toString() ?? '');
    final proteinCtrl =
        TextEditingController(text: food?['total_protein']?.toString() ?? '');
    final isEditing = food != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Makanan' : 'Tambah Makanan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: CmColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Makanan'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: grammageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Gramasi (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Kalori per Porsi (kkal)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fatCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lemak (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: carboCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Karbohidrat (g)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: proteinCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Protein (g)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final data = {
                    'name': nameCtrl.text.trim(),
                    'grammage': double.tryParse(grammageCtrl.text) ?? 0,
                    'calories_per_portion':
                        double.tryParse(caloriesCtrl.text) ?? 0,
                    'total_fat': double.tryParse(fatCtrl.text) ?? 0,
                    'total_carbo': double.tryParse(carboCtrl.text) ?? 0,
                    'total_protein': double.tryParse(proteinCtrl.text) ?? 0,
                  };
                  try {
                    if (isEditing) {
                      final foodId = food['food_id'] ?? food['id'];
                      await _api.put('/trainer/foods/$foodId', data: data);
                    } else {
                      await _api.post('/trainer/foods', data: data);
                    }
                    if (mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEditing
                              ? 'Makanan diperbarui'
                              : 'Makanan ditambahkan'),
                          backgroundColor: CmColors.primaryGreen,
                        ),
                      );
                    }
                    _load(page: _currentPage);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: $e')),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Simpan' : 'Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CmBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Add Button Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Tambah Makanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari makanan...',
                  prefixIcon: const Icon(Icons.search, color: CmColors.primaryGreen),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _load();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (value) {
                  setState(() => _searchQuery = value.trim());
                  _load();
                },
              ),
            ),
            // Food list
            Expanded(
              child: RefreshIndicator(
                color: CmColors.primaryGreen,
                onRefresh: () => _load(page: _currentPage),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: CmColors.primaryGreen))
                    : _foods.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Icon(Icons.restaurant_menu,
                                  size: 64, color: Colors.black26),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada data makanan.\nTap + untuk menambahkan.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 16),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _foods.length + 1, // +1 for pagination
                            itemBuilder: (_, i) {
                              if (i == _foods.length) {
                                // Pagination controls
                                return _buildPagination();
                              }
                              final f = _foods[i];
                              return _buildFoodCard(f);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> f) {
    final foodId = (f['food_id'] as num?)?.toInt() ??
        (f['id'] as num?)?.toInt() ?? 0;
    final name = f['name']?.toString() ?? '';
    final grammage = f['grammage']?.toString() ?? '0';
    final calories = f['calories_per_portion']?.toString() ?? '0';
    final fat = f['total_fat']?.toString() ?? '0';
    final carbo = f['total_carbo']?.toString() ?? '0';
    final protein = f['total_protein']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CmCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CmColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: CmColors.accentOrange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CmColors.primaryGreen,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${grammage}g · $calories kkal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  icon: const Icon(Icons.more_vert, color: Colors.black54),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showForm(f);
                    } else if (val == 'delete') {
                      _delete(foodId);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: CmColors.primaryGreen),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _NutrientChip(
                    label: 'Protein', value: '${protein}g', color: CmColors.protein),
                const SizedBox(width: 6),
                _NutrientChip(
                    label: 'Karbo', value: '${carbo}g', color: CmColors.carbs),
                const SizedBox(width: 6),
                _NutrientChip(
                    label: 'Lemak', value: '${fat}g', color: CmColors.fat),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_lastPage <= 1) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () => _load(page: _currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: CmColors.primaryGreen,
          ),
          Text(
            'Halaman $_currentPage dari $_lastPage',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: CmColors.primaryGreen,
            ),
          ),
          IconButton(
            onPressed: _currentPage < _lastPage
                ? () => _load(page: _currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: CmColors.primaryGreen,
          ),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
