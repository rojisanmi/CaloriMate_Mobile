import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';

/// Baris item latihan yang ditambahkan inline saat create/edit program
class _ItemRow {
  final nameCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  String intensity = '';

  _ItemRow({String name = '', String duration = '', String intensity = ''}) {
    nameCtrl.text = name;
    durationCtrl.text = duration;
    this.intensity = intensity;
  }

  void dispose() {
    nameCtrl.dispose();
    durationCtrl.dispose();
  }

  Map<String, dynamic> toMap() => {
        'exercise_name': nameCtrl.text.trim(),
        'duration_minutes': int.tryParse(durationCtrl.text.trim()) ?? 0,
        'intensity_level': intensity.isEmpty ? null : intensity,
      };
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
    } else {
      _itemRows.add(_ItemRow());
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

      if (!_isEditing) {
        final validItems = _itemRows
            .map((r) => r.toMap())
            .where((m) => (m['exercise_name'] as String).isNotEmpty)
            .toList();
        if (validItems.isNotEmpty) data['items'] = validItems;
        await _api.post('/trainer/programs', data: data);
      } else {
        final pid = widget.program!['program_id'] ?? widget.program!['id'];
        await _api.put('/trainer/programs/$pid', data: data);
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
            const Text(
              'Buat program baru beserta item latihannya',
              style: TextStyle(fontSize: 11, color: Colors.white70),
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
                              hint: const Text('Pilih tingkat',
                                  style: TextStyle(fontSize: 13, color: Colors.black38)),
                              decoration: _inputDeco(null),
                              items: _difficulties
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (v) => setState(() => _difficulty = v ?? ''),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Item Latihan section (create only) ──
                  if (!_isEditing) ...[
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 16),
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
                                    child: StatefulBuilder(
                                      builder: (_, setIntensity) => Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _labelSm('Intensitas'),
                                          const SizedBox(height: 4),
                                          DropdownButtonFormField<String>(
                                            value: row.intensity.isEmpty
                                                ? null
                                                : row.intensity,
                                            isDense: true,
                                            hint: const Text('Pilih',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black38)),
                                            decoration: _inputDecoSm(null),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'low',
                                                  child: Text('low',
                                                      style: TextStyle(fontSize: 13))),
                                              DropdownMenuItem(
                                                  value: 'medium',
                                                  child: Text('medium',
                                                      style: TextStyle(fontSize: 13))),
                                              DropdownMenuItem(
                                                  value: 'high',
                                                  child: Text('high',
                                                      style: TextStyle(fontSize: 13))),
                                            ],
                                            onChanged: (v) {
                                              setIntensity(() => row.intensity = v ?? '');
                                            },
                                          ),
                                        ],
                                      ),
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
