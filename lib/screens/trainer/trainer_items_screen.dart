import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';

class TrainerItemsScreen extends StatefulWidget {
  final int programId;
  final String programTitle;
  final Map<String, dynamic>? programData;

  const TrainerItemsScreen({
    super.key,
    required this.programId,
    required this.programTitle,
    this.programData,
  });

  @override
  State<TrainerItemsScreen> createState() => _TrainerItemsScreenState();
}

class _TrainerItemsScreenState extends State<TrainerItemsScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<Map<String, dynamic>> result = [];

    // ── Stage 1: GET /trainer/programs/{id}/items ──
    // This is the proper endpoint now that index() method exists in the controller.
    try {
      final res = await _api.get(
        '/trainer/programs/${widget.programId}/items',
        query: {
          if (_query.isNotEmpty) 'q': _query,
          'per_page': 100,
        },
      );
      result = _parseItems(res.data);
      debugPrint('[Items] Stage 1 OK: ${result.length} items');
    } catch (e1) {
      debugPrint('[Items] Stage 1 failed: $e1');
    }

    // ── Stage 2 fallback: GET /trainer/programs/{id} (show endpoint) ──
    // ProgramController@show returns { program: {...}, items: { data: [...] } }
    if (result.isEmpty) {
      try {
        final res2 = await _api.get('/trainer/programs/${widget.programId}');
        final d = res2.data;
        if (d is Map) {
          // { items: { data: [...] } }
          final itemsNode = d['items'];
          if (itemsNode is Map && itemsNode['data'] is List) {
            result = (itemsNode['data'] as List)
                .whereType<Map<String, dynamic>>()
                .toList();
          } else if (itemsNode is List) {
            result = itemsNode.whereType<Map<String, dynamic>>().toList();
          }
        }
        debugPrint('[Items] Stage 2 OK: ${result.length} items');
      } catch (e2) {
        debugPrint('[Items] Stage 2 failed: $e2');
      }
    }

    if (mounted) {
      setState(() {
        _items = result;
        _loading = false;
      });
    }
  }

  /// Parse Laravel paginated or plain list response into a typed list.
  List<Map<String, dynamic>> _parseItems(dynamic data) {
    if (data == null) return [];
    // Laravel paginator: { "data": [...], "total": n, ... }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    // Plain list
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }


  // Shallow route: DELETE /trainer/items/{id}
  Future<void> _delete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hapus Item?', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Hapus item latihan "$name"?',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/trainer/items/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item dihapus'),
            backgroundColor: CmColors.primaryGreen,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  void _showEditForm(Map<String, dynamic> item) {
    final nameCtrl =
        TextEditingController(text: item['exercise_name']?.toString() ?? '');
    final durationCtrl = TextEditingController(
        text: item['duration_minutes']?.toString() ?? '');
    String intensity = item['intensity_level']?.toString() ?? 'low';
    if (!['low', 'medium', 'high'].contains(intensity)) intensity = 'low';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Item Latihan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: CmColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(nameCtrl, 'Nama Latihan', 'mis. Push Up'),
              const SizedBox(height: 12),
              _buildTextField(durationCtrl, 'Durasi (menit)', 'mis. 10',
                  isNumber: true),
              const SizedBox(height: 12),
              _buildIntensityRow(intensity, (v) => setSS(() => intensity = v)),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    final itemId =
                        (item['program_item_id'] as num?)?.toInt() ??
                            (item['id'] as num?)?.toInt() ??
                            0;
                    await _api.put('/trainer/items/$itemId', data: {
                      'exercise_name': nameCtrl.text.trim(),
                      'duration_minutes':
                          int.tryParse(durationCtrl.text) ?? 0,
                      'intensity_level': intensity,
                    });
                    if (mounted) Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Simpan Perubahan',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddForm() {
    final nameCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String intensity = 'low';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: CmColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add,
                        color: CmColors.accentOrange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tambah Item Latihan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: CmColors.primaryGreen,
                        ),
                      ),
                      Text(
                        widget.programTitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(nameCtrl, 'Nama Latihan', 'mis. Push Up'),
              const SizedBox(height: 12),
              _buildTextField(durationCtrl, 'Durasi (menit)', 'mis. 10',
                  isNumber: true),
              const SizedBox(height: 12),
              _buildIntensityRow(intensity, (v) => setSS(() => intensity = v)),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await _api.post(
                      '/trainer/programs/${widget.programId}/items',
                      data: {
                        'exercise_name': nameCtrl.text.trim(),
                        'duration_minutes':
                            int.tryParse(durationCtrl.text) ?? 0,
                        'intensity_level': intensity,
                      },
                    );
                    if (mounted) Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CmColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Tambah Item',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmColors.primaryGreen)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: CmColors.primaryGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntensityRow(String current, void Function(String) onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Intensitas',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CmColors.primaryGreen)),
        const SizedBox(height: 8),
        Row(
          children: ['low', 'medium', 'high'].map((level) {
            final isSelected = current == level;
            final color = level == 'low'
                ? Colors.blue
                : level == 'high'
                    ? Colors.red
                    : Colors.amber.shade700;
            final label =
                level == 'low' ? 'low' : level == 'high' ? 'high' : 'medium';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => onTap(level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? color : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _intensityBgColor(String? level) {
    switch (level) {
      case 'high':
        return Colors.red.shade50;
      case 'medium':
        return Colors.amber.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  Color _intensityTextColor(String? level) {
    switch (level) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.amber.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prog = widget.programData;
    final type = prog?['type']?.toString() ?? '';
    final difficulty = prog?['difficulty']?.toString() ?? '';
    final totalDuration = prog?['total_duration'];

    return Scaffold(
      backgroundColor: CmColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: CmColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(widget.programTitle,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _showAddForm,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('Tambah Item',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Header card ───
          Container(
            width: double.infinity,
            color: CmColors.primaryGreen,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Program Latihan',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60),
                      ),
                    ),
                    const Text(' / ',
                        style: TextStyle(
                            fontSize: 11, color: Colors.white38)),
                    Text(
                      widget.programTitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.programTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (type.isNotEmpty || difficulty.isNotEmpty || totalDuration != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        if (type.isNotEmpty) type,
                        if (difficulty.isNotEmpty) difficulty,
                        if (totalDuration != null &&
                            totalDuration.toString() != '0')
                          '$totalDuration menit',
                      ].join(' · '),
                      style: const TextStyle(
                          fontSize: 12,
                          color: CmColors.accentOrange),
                    ),
                  ),
              ],
            ),
          ),

          // ─── Search bar ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Cari item latihan...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: Colors.black38),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: Colors.black38),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (v) {
                        setState(() => _query = v.trim());
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Table ───
          Expanded(
            child: RefreshIndicator(
              color: CmColors.primaryGreen,
              onRefresh: _load,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: CmColors.primaryGreen))
                  : _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Icon(Icons.sports_gymnastics,
                                size: 64, color: Colors.black12),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada item latihan.\nTap "Tambah Item" untuk menambahkan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black38, fontSize: 13),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Table header
                                Container(
                                  color: const Color(0xFFEFE6D2)
                                      .withValues(alpha: 0.6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      _th('NO', 32),
                                      _th('NAMA LATIHAN', null, flex: true),
                                      _th('DURASI', 68, center: true),
                                      _th('INTENSITAS', 82, center: true),
                                      _th('AKSI', 100, right: true),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                                // Table rows
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFF5F5F5)),
                                  itemBuilder: (_, i) {
                                    final item = _items[i];
                                    final itemId =
                                        (item['program_item_id'] as num?)
                                                ?.toInt() ??
                                            (item['id'] as num?)?.toInt() ??
                                            0;
                                    final name =
                                        item['exercise_name']?.toString() ??
                                            '';
                                    final duration = item['duration_minutes'];
                                    final intensity =
                                        item['intensity_level']?.toString() ??
                                            '';

                                    return Container(
                                      color: i.isEven
                                          ? Colors.white
                                          : Colors.grey.shade50,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          // NO
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black38),
                                            ),
                                          ),
                                          // NAMA
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          // DURASI
                                          SizedBox(
                                            width: 68,
                                            child: Text(
                                              duration != null
                                                  ? '$duration mnt'
                                                  : '-',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54),
                                            ),
                                          ),
                                          // INTENSITAS
                                          SizedBox(
                                            width: 82,
                                            child: Center(
                                              child: intensity.isEmpty
                                                  ? const Text('-',
                                                      style: TextStyle(
                                                          fontSize: 12))
                                                  : Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _intensityBgColor(
                                                                intensity),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        intensity,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              _intensityTextColor(
                                                                  intensity),
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          // AKSI
                                          SizedBox(
                                            width: 100,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                _actionBtn(
                                                  'Edit',
                                                  CmColors.primaryGreen,
                                                  () => _showEditForm(item),
                                                ),
                                                const SizedBox(width: 6),
                                                _actionBtn(
                                                  'Hapus',
                                                  Colors.red,
                                                  () => _delete(itemId, name),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),

          // Back link
          Container(
            color: Colors.white,
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left,
                      size: 18, color: Colors.black45),
                  Text(
                    'Kembali ke daftar program',
                    style: TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _th(String text, double? width,
      {bool flex = false, bool center = false, bool right = false}) {
    final t = Text(
      text,
      textAlign: center
          ? TextAlign.center
          : right
              ? TextAlign.right
              : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: CmColors.primaryGreen,
        letterSpacing: 0.5,
      ),
    );
    if (flex) return Expanded(child: t);
    return SizedBox(width: width, child: t);
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
