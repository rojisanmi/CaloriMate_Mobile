import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:path/path.dart' as p;

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
import '../diary/add_food_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiClient.instance;
  final _bb = TextEditingController();
  final _tb = TextEditingController();
  final _umur = TextEditingController();
  String _gender = 'L';
  bool _loading = true;
  bool _saving = false;

  String? _localAvatarPath;
  TimeOfDay? _foodReminderTime;
  TimeOfDay? _exerciseReminderTime;
  final _picker = ImagePicker();

  static const _mealCategories = [
    ('breakfast', 'Sarapan', Icons.free_breakfast_outlined),
    ('lunch', 'Makan Siang', Icons.lunch_dining_outlined),
    ('dinner', 'Makan Malam', Icons.dinner_dining_outlined),
    ('snack', 'Camilan', Icons.cookie_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bb.dispose();
    _tb.dispose();
    _umur.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.fetchProfile();
      if (!mounted) return;
      final client = auth.client;
      if (client != null) {
        _bb.text = client['bb']?.toString() ?? '';
        _tb.text = client['tb']?.toString() ?? '';
        _umur.text = client['umur']?.toString() ?? '';
        _gender = client['gender']?.toString() ?? 'L';
        _foodReminderTime = _parseTime(client['food_reminder_time']?.toString());
        _exerciseReminderTime = _parseTime(client['exercise_reminder_time']?.toString());
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'bb': double.parse(_bb.text),
        'tb': double.parse(_tb.text),
        'umur': int.parse(_umur.text),
        'gender': _gender,
        'food_reminder_time': _formatTime(_foodReminderTime),
        'exercise_reminder_time': _formatTime(_exerciseReminderTime),
      };

      if (_localAvatarPath != null && File(_localAvatarPath!).existsSync()) {
        final file = File(_localAvatarPath!);
        final form = dio_package.FormData.fromMap({
          ...payload,
          'photo': await dio_package.MultipartFile.fromFile(
            file.path,
            filename: p.basename(file.path),
          ),
        });
        await _api.dio.post(
          '/client/profile',
          data: form,
          options: dio_package.Options(contentType: 'multipart/form-data'),
        );
      } else {
        await _api.post('/client/profile', data: payload);
      }

      if (!mounted) return;
      await context.read<AuthProvider>().fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: CmColors.primaryGreen,
          ),
        );
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: CmColors.primaryGreen),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: CmColors.primaryGreen),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open, color: CmColors.primaryGreen),
                title: const Text('Pilih dari File Manager'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFromFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
          : CmBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CmCard(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showPhotoOptions,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: CmColors.accentOrange,
                                  child: _buildAvatarWidget(auth),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: CmColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            auth.displayName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            auth.user?['email']?.toString() ?? '',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _showPhotoOptions,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Ganti Foto'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Input Makanan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Catat makanan per kategori seperti di web',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ..._mealCategories.map((cat) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddFoodScreen(
                                          category: cat.$1,
                                          categoryLabel: cat.$2,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(cat.$3, size: 18),
                                  label: Text('Tambah ${cat.$2}'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: CmColors.primaryGreen,
                                    side: const BorderSide(color: CmColors.primaryGreen),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    CmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Pengaturan Pengingat',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atur jam pengingat input makanan dan jadwal olahraga',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          _ReminderRow(
                            label: 'Pengingat Input Makanan',
                            time: _foodReminderTime,
                            onPick: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _foodReminderTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _foodReminderTime = t);
                            },
                            onClear: () => setState(() => _foodReminderTime = null),
                          ),
                          const Divider(height: 24),
                          _ReminderRow(
                            label: 'Pengingat Jadwal Olahraga',
                            time: _exerciseReminderTime,
                            onPick: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _exerciseReminderTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _exerciseReminderTime = t);
                            },
                            onClear: () => setState(() => _exerciseReminderTime = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Data Pribadi',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            controller: TextEditingController(text: auth.displayName),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _tb,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Tinggi Badan (cm)'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bb,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Berat Badan (kg)'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _umur,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Umur'),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Jenis Kelamin',
                            style: TextStyle(fontWeight: FontWeight.w600, color: CmColors.primaryGreen),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Laki-laki'),
                                  value: 'L',
                                  groupValue: _gender,
                                  onChanged: (v) => setState(() => _gender = v!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Perempuan'),
                                  value: 'P',
                                  groupValue: _gender,
                                  onChanged: (v) => setState(() => _gender = v!),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Simpan Perubahan'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarWidget(AuthProvider auth) {
    if (_localAvatarPath != null && File(_localAvatarPath!).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(_localAvatarPath!),
          width: 92,
          height: 92,
          fit: BoxFit.cover,
        ),
      );
    }

    final client = auth.client;
    final photoUrl = client?['photo_url']?.toString();
    final photoPath = client?['photo_path']?.toString();
    final serverPath = photoUrl ?? photoPath;
    if (serverPath != null && serverPath.isNotEmpty) {
      final url = serverPath.startsWith('http')
          ? serverPath
          : '${ApiConfig.storageUrl}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
      return ClipOval(
        child: Image.network(
          url,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsWidget(auth),
        ),
      );
    }

    return _initialsWidget(auth);
  }

  Widget _initialsWidget(AuthProvider auth) {
    return Text(
      auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'U',
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: CmColors.primaryGreen,
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (x == null) return;
      setState(() => _localAvatarPath = x.path);
      await _uploadAvatar(File(x.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (x == null) return;
      setState(() => _localAvatarPath = x.path);
      await _uploadAvatar(File(x.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  Future<void> _pickFromFile() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (res == null || res.files.isEmpty) return;
      final path = res.files.first.path;
      if (path == null) return;
      setState(() => _localAvatarPath = path);
      await _uploadAvatar(File(path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar(File file) async {
    try {
      final form = dio_package.FormData.fromMap({
        'photo': await dio_package.MultipartFile.fromFile(
          file.path,
          filename: p.basename(file.path),
        ),
      });
      await _api.dio.post(
        '/client/profile',
        data: form,
        options: dio_package.Options(contentType: 'multipart/form-data'),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().fetchProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil diperbarui'),
            backgroundColor: CmColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e')),
        );
      }
    }
  }
}

class _ReminderRow extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ReminderRow({
    required this.label,
    required this.time,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                time == null ? 'Belum diatur' : time!.format(context),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
        if (time != null)
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Hapus',
          ),
        TextButton(onPressed: onPick, child: const Text('Pilih')),
      ],
    );
  }
}
