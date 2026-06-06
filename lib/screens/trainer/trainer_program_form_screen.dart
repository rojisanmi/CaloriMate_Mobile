import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class TrainerProgramFormScreen extends StatefulWidget {
  final Map<String, dynamic>? program; // null = create, non-null = edit

  const TrainerProgramFormScreen({super.key, this.program});

  @override
  State<TrainerProgramFormScreen> createState() => _TrainerProgramFormScreenState();
}

class _TrainerProgramFormScreenState extends State<TrainerProgramFormScreen> {
  final _api = ApiClient.instance;
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _type = 'strength';
  String _difficulty = 'medium';
  bool _saving = false;

  bool get _isEditing => widget.program != null;

  static const _types = ['strength', 'cardio', 'flexibility', 'hiit', 'yoga'];
  static const _difficulties = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _title.text = widget.program!['title']?.toString() ?? '';
      _description.text = widget.program!['description']?.toString() ?? '';
      _type = widget.program!['type']?.toString() ?? 'strength';
      _difficulty = widget.program!['difficulty']?.toString() ?? 'medium';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'type': _type,
        'difficulty': _difficulty,
      };
      if (_isEditing) {
        await _api.put('/trainer/programs/${widget.program!['id']}', data: data);
      } else {
        await _api.post('/trainer/programs', data: data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Program diperbarui' : 'Program dibuat'),
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Program' : 'Buat Program Baru')),
      body: CmBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: CmCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Nama Program'),
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Tipe'),
                    items: _types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t[0].toUpperCase() + t.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: _difficulties
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d == 'low'
                                  ? 'Mudah'
                                  : d == 'high'
                                      ? 'Sulit'
                                      : 'Sedang'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Simpan Perubahan' : 'Buat Program'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
