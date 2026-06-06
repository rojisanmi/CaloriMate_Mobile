import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:path/path.dart' as p;

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  String? _localAvatarPath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.fetchTrainerProfile();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
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
              const Text('Ganti Foto Profil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
            ],
          ),
        ),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
        '/trainer/profile',
        data: form,
        options: dio_package.Options(contentType: 'multipart/form-data'),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().fetchTrainerProfile();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Trainer')),
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
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 16),
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
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: CmColors.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Trainer',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CmColors.accentOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Informasi Akun',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 12),
                          _InfoRow(
                              label: 'Username', value: auth.displayName),
                          _InfoRow(
                              label: 'Email',
                              value: auth.user?['email']?.toString() ?? '-'),
                          _InfoRow(label: 'Role', value: 'Trainer'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                        },
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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
        child: Image.file(File(_localAvatarPath!),
            width: 92, height: 92, fit: BoxFit.cover),
      );
    }

    final trainer = auth.trainer;
    final photoUrl = trainer?['photo_url']?.toString();
    final photoPath = trainer?['photo_path']?.toString();
    final serverPath = photoUrl ?? photoPath;
    if (serverPath != null && serverPath.isNotEmpty) {
      final url = serverPath.startsWith('http')
          ? serverPath
          : '${ApiConfig.storageUrl}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
      return ClipOval(
        child: Image.network(url,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsWidget(auth)),
      );
    }

    return _initialsWidget(auth);
  }

  Widget _initialsWidget(AuthProvider auth) {
    return Text(
      auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'T',
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: CmColors.primaryGreen,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
