import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../config/api_config.dart';
import '../../widgets/cm_background.dart';

class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  bool _saving = false;

  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _keahlianCtrl = TextEditingController();

  File? _localAvatar;
  File? _localSertifikasi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _namaCtrl.dispose();
    _keahlianCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      await auth.fetchTrainerProfile();

      _usernameCtrl.text = auth.displayName;
      _emailCtrl.text = auth.user?['email']?.toString() ?? '';
      _namaCtrl.text = auth.trainer?['nama']?.toString() ?? '';
      _keahlianCtrl.text = auth.trainer?['keahlian']?.toString() ?? '';
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
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: CmColors.primaryGreen),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: source, imageQuality: 80);
      if (x != null) {
        setState(() => _localAvatar = File(x.path));
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  Future<void> _pickSertifikasi() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _localSertifikasi = File(result.files.single.path!));
      }
    } catch (e) {
      _showError('Gagal memilih file: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final formData = dio_package.FormData.fromMap({
        'email': _emailCtrl.text.trim(),
        'nama': _namaCtrl.text.trim(),
        'keahlian': _keahlianCtrl.text.trim(),
      });

      if (_localAvatar != null) {
        formData.files.add(MapEntry(
          'photo',
          await dio_package.MultipartFile.fromFile(
            _localAvatar!.path,
            filename: p.basename(_localAvatar!.path),
          ),
        ));
      }

      if (_localSertifikasi != null) {
        formData.files.add(MapEntry(
          'sertifikasi',
          await dio_package.MultipartFile.fromFile(
            _localSertifikasi!.path,
            filename: p.basename(_localSertifikasi!.path),
          ),
        ));
      }

      await _api.dio.post(
        '/trainer/profile',
        data: formData,
        options: dio_package.Options(contentType: 'multipart/form-data'),
      );

      if (!mounted) return;
      await context.read<AuthProvider>().fetchTrainerProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil disimpan'),
            backgroundColor: CmColors.primaryGreen,
          ),
        );
      }
    } on dio_package.DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        if (data != null && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first.first.toString();
          _showError(firstError);
          return;
        }
      }
      _showError('Gagal menyimpan profil');
    } catch (e) {
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return CmBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
            : RefreshIndicator(
                color: CmColors.primaryGreen,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: CmColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kelola data trainer dan sertifikasi kamu',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Avatar Card
                      _buildAvatarCard(auth),
                      const SizedBox(height: 16),

                      // Personal Info Card
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 16),

                      // Sertifikasi Card
                      _buildSertifikasiCard(auth),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text('Logout', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CmColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildAvatarCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CmColors.accentOrange.withValues(alpha: 0.2),
              border: Border.all(color: CmColors.accentOrange.withValues(alpha: 0.5), width: 3),
            ),
            child: ClipOval(child: _buildAvatarImage(auth)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.trainer?['nama']?.toString() ?? auth.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CmColors.primaryGreen),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CmColors.accentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Trainer',
                        style: TextStyle(fontWeight: FontWeight.bold, color: CmColors.accentOrange, fontSize: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.user?['email']?.toString() ?? '',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _showPhotoOptions,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CmColors.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(AuthProvider auth) {
    if (_localAvatar != null) {
      return Image.file(_localAvatar!, fit: BoxFit.cover);
    }
    final serverPath = auth.trainer?['photo_url']?.toString() ?? auth.trainer?['photo_path']?.toString();
    if (serverPath != null && serverPath.isNotEmpty) {
      final url = serverPath.startsWith('http') ? serverPath : '${ApiConfig.storageUrl.replaceAll(RegExp(r'/$'), '')}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildAvatarInitials(auth));
    }
    return _buildAvatarInitials(auth);
  }

  Widget _buildAvatarInitials(AuthProvider auth) {
    final name = auth.trainer?['nama']?.toString() ?? auth.displayName;
    final initial = name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'TR';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: CmColors.primaryGreen),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Pribadi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CmColors.primaryGreen)),
          const SizedBox(height: 4),
          const Text('Username tidak dapat diubah karena merupakan identitas akun.', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),

          _buildLabel('Username'),
          TextFormField(
            controller: _usernameCtrl,
            readOnly: true,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            decoration: _inputDeco().copyWith(fillColor: Colors.grey.shade50),
          ),
          const SizedBox(height: 16),

          _buildLabel('Email'),
          TextFormField(
            controller: _emailCtrl,
            decoration: _inputDeco(),
            validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Email tidak valid' : null,
          ),
          const SizedBox(height: 16),

          _buildLabel('Nama Lengkap'),
          TextFormField(
            controller: _namaCtrl,
            decoration: _inputDeco(),
            validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 16),

          _buildLabel('Keahlian'),
          TextFormField(
            controller: _keahlianCtrl,
            decoration: _inputDeco(hint: 'mis. Strength, Cardio, Nutrisi'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Keahlian wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CmColors.primaryGreen)),
    );
  }

  InputDecoration _inputDeco({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black26),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CmColors.primaryGreen)),
    );
  }

  Widget _buildSertifikasiCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sertifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CmColors.primaryGreen)),
          const SizedBox(height: 4),
          const Text('Upload bukti sertifikasi keahlian kamu (jpg, png, atau pdf, maks 2 MB).', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),

          // Preview Area
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFE6D2).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildSertifikasiPreview(auth),
          ),
          const SizedBox(height: 12),

          InkWell(
            onTap: _pickSertifikasi,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 16, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text('Pilih file sertifikasi', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSertifikasiPreview(AuthProvider auth) {
    if (_localSertifikasi != null) {
      final path = _localSertifikasi!.path.toLowerCase();
      if (path.endsWith('.pdf')) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
              SizedBox(height: 8),
              Text('PDF Terpilih', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      } else {
        return Image.file(_localSertifikasi!, fit: BoxFit.contain);
      }
    }

    final sertPath = auth.trainer?['sertifikasi']?.toString();
    if (sertPath != null && sertPath.isNotEmpty) {
      final isPdf = sertPath.toLowerCase().endsWith('.pdf');
      final url = sertPath.startsWith('http') ? sertPath : '${ApiConfig.storageUrl}/${sertPath.replaceFirst(RegExp(r'^/'), '')}';

      if (isPdf) {
        return Center(
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(url)),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf, size: 48, color: CmColors.primaryGreen),
                SizedBox(height: 8),
                Text('Lihat Sertifikasi (PDF)', style: TextStyle(fontWeight: FontWeight.bold, color: CmColors.primaryGreen)),
              ],
            ),
          ),
        );
      } else {
        return Image.network(url, fit: BoxFit.contain);
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.assignment_ind, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        const Text('Belum ada sertifikasi', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
