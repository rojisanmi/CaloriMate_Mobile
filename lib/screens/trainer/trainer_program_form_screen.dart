import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';

/// Baris item latihan yang ditambahkan inline saat create/edit program
class _ItemRow {
  final int? id; // program_item_id untuk item yang sudah ada (null = baru)
  final nameCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  String intensity = '';

  _ItemRow({this.id, String name = '', String duration = '', String intensity = ''}) {
    nameCtrl.text = name;
    durationCtrl.text = duration;
    this.intensity = intensity;
  }

  void dispose() {
    nameCtrl.dispose();
    durationCtrl.dispose();
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exercise_name': nameCtrl.text.trim(),
        'duration_minutes': int.tryParse(durationCtrl.text.trim()) ?? 0,
        'intensity_level': intensity.isEmpty ? null : intensity,
      };
}

/// Normalisasi nilai intensitas agar cocok dengan opsi dropdown (low/medium/high).
String _normalizeIntensity(dynamic raw) {
  final v = raw?.toString().toLowerCase().trim() ?? '';
  switch (v) {
    case 'low':
    case 'rendah':
      return 'low';
    case 'medium':
    case 'sedang':
      return 'medium';
    case 'high':
    case 'tinggi':
      return 'high';
    default:
      return '';
  }
}

class TrainerProgramFormScreen extends StatefulWidget {
  final Map<String, dynamic>? program;

  const TrainerProgramFormScreen({super.key, this.program});

  @override
  State<TrainerProgramFormScreen> createState() =>
      _TrainerProgramFormScreenState();
}

class _TrainerProgramFormScreenState extends State<TrainerProgramFormScreen> {
  final _api = ApiClient.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  String _difficulty = '';
  bool _saving = false;
  bool _loadingItems = false;

  final List<_ItemRow> _itemRows = [];

  bool get _isEditing => widget.program != null;

  static const _difficulties = ['Low', 'Medium', 'High'];
  static const _diffApiMap = {
    'Low': 'low', 'Medium': 'medium', 'High': 'high',
    'low': 'low', 'medium': 'medium', 'high': 'high',
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.program!['name']?.toString() ??
          widget.program!['title']?.toString() ?? '';
      _typeCtrl.text = widget.program!['type']?.toString() ?? '';
      final rawDiff = widget.program!['difficulty']?.toString().toLowerCase() ?? '';
      _difficulty = rawDiff.isEmpty ? '' : rawDiff[0].toUpperCase() + rawDiff.substring(1);
      if (!_difficulties.contains(_difficulty)) _difficulty = '';
      _loadItems();
    } else {
      _itemRows.add(_ItemRow());
    }
  }

  int? get _programId =>
      (widget.program?['program_id'] as num?)?.toInt() ??
      (widget.program?['id'] as num?)?.toInt();

  /// Memuat item latihan yang sudah ada untuk program yang sedang diedit.
  Future<void> _loadItems() async {
    final pid = _programId;
    if (pid == null) return;
    setState(() => _loadingItems = true);
    try {
      final res = await _api.get('/trainer/programs/$pid', query: {'per_page': 100});
      final data = res.data as Map<String, dynamic>;
      // items bisa berupa paginator {data: [...]} atau list langsung
      final itemsRaw = data['items'];
      final List list = itemsRaw is Map && itemsRaw['data'] is List
          ? itemsRaw['data'] as List
          : (itemsRaw is List ? itemsRaw : []);
      if (!mounted) return;
      setState(() {
        for (final r in _itemRows) {
          r.dispose();
        }
        _itemRows
          ..clear()
          ..addAll(list.map((e) {
            final m = e as Map<String, dynamic>;
            final dur = m['duration_minutes'];
            return _ItemRow(
              id: (m['program_item_id'] as num?)?.toInt() ?? (m['id'] as num?)?.toInt(),
              name: m['exercise_name']?.toString() ?? '',
              duration: dur == null ? '' : dur.toString(),
              intensity: _normalizeIntensity(m['intensity_level']),
            );
          }));
        _loadingItems = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    for (final row in _itemRows) row.dispose();
    super.dispose();
  }

  void _addRow() => setState(() => _itemRows.add(_ItemRow()));

  void _removeRow(int index) {
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'difficulty': _diffApiMap[_difficulty] ?? _difficulty.toLowerCase(),
      };

      final validItems = _itemRows
          .map((r) => r.toMap())
          .where((m) => (m['exercise_name'] as String).isNotEmpty)
          .toList();

      if (!_isEditing) {
        if (validItems.isNotEmpty) data['items'] = validItems;
        await _api.post('/trainer/programs', data: data);
      } else {
        // Selalu kirim items saat edit agar penambahan/penghapusan ikut tersimpan
        data['items'] = validItems;
        await _api.put('/trainer/programs/$_programId', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Program diperbarui' : 'Program berhasil dibuat'),
          backgroundColor: CmColors.primaryGreen,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CmColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: CmColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Program Latihan' : 'Buat Program Latihan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _isEditing
                  ? 'Ubah detail program & item latihannya'
                  : 'Buat program baru beserta item latihannya',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: CmBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Nama Program ──
                  _label('Nama Program'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDeco('mis. Full Body Workout'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Tipe & Tingkat (2 kolom) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Tipe'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _typeCtrl,
                              decoration: _inputDeco('mis. HIIT, Cardio'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Tingkat Kesulitan'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _difficulty.isEmpty ? null : _difficulty,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: CmColors.primaryGreen),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              hint: const Text('Pilih tingkat',
                                  style: TextStyle(fontSize: 13, color: Colors.black38)),
                              decoration: _inputDeco(null),
                              items: _difficulties
                                  .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (v) => setState(() => _difficulty = v ?? ''),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Item Latihan section ──
                  ...[
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 16),
                    if (_loadingItems)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: CmColors.primaryGreen),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Item Latihan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: CmColors.primaryGreen,
                          ),
                        ),
                        GestureDetector(
                          onTap: _addRow,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: CmColors.backgroundCream,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFD4C8A8)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 14, color: CmColors.primaryGreen),
                                SizedBox(width: 4),
                                Text(
                                  'Tambah Item',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CmColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (!_loadingItems && _itemRows.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Text(
                          'Belum ada item latihan.\nKlik "Tambah Item" untuk menambahkan gerakan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),

                    // Item rows — each row is a Card with VERTICAL layout to avoid overflow
                    ...List.generate(_itemRows.length, (i) {
                      final row = _itemRows[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row header: label + X button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Item ${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: CmColors.primaryGreen,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _removeRow(i)),
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Icon(Icons.close,
                                          size: 14, color: Colors.red.shade400),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Nama Latihan (full width)
                              _labelSm('Nama Latihan'),
                              const SizedBox(height: 4),
                              TextField(
                                controller: row.nameCtrl,
                                decoration: _inputDecoSm('mis. Push Up'),
                              ),
                              const SizedBox(height: 10),

                              // Durasi + Intensitas (2 kolom)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Durasi
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _labelSm('Durasi (menit)'),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: row.durationCtrl,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoSm('mis. 10'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Intensitas
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _labelSm('Intensitas'),
                                        const SizedBox(height: 4),
                                        DropdownButtonFormField<String>(
                                          value: row.intensity.isEmpty
                                              ? null
                                              : row.intensity,
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 20,
                                              color: CmColors.primaryGreen),
                                          dropdownColor: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          hint: const Text('Pilih',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black38)),
                                          decoration: _inputDecoSm(null),
                                          items: const [
                                            DropdownMenuItem(
                                                value: 'low',
                                                child: Text('Low',
                                                    style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(
                                                value: 'medium',
                                                child: Text('Medium',
                                                    style: TextStyle(fontSize: 13))),
                                            DropdownMenuItem(
                                                value: 'high',
                                                child: Text('High',
                                                    style: TextStyle(fontSize: 13))),
                                          ],
                                          onChanged: (v) {
                                            setState(() => row.intensity = v ?? '');
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),

                  // ── Actions ──
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CmColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Simpan Program',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black54,
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: const Text('Batal',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF444444)),
      );

  Widget _labelSm(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
      );

  InputDecoration _inputDeco(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CmColors.primaryGreen, width: 2),
        ),
      );

  InputDecoration _inputDecoSm(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CmColors.primaryGreen, width: 1.5),
        ),
      );
}
