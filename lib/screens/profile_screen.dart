import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  final _bbC = TextEditingController();
  final _tbC = TextEditingController();
  final _umurC = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await ProfileService.getProfile();
      if (mounted) {
        setState(() { _data = d; _loading = false; });
        final c = d['user']?['client'];
        if (c != null) {
          _bbC.text = '${c['bb'] ?? ''}';
          _tbC.text = '${c['tb'] ?? ''}';
          _umurC.text = '${c['umur'] ?? ''}';
        }
      }
    } catch (e) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProfileService.updateProfile(
        bb: double.tryParse(_bbC.text) ?? 0,
        tb: double.tryParse(_tbC.text) ?? 0,
        umur: int.tryParse(_umurC.text) ?? 0,
      );
      if (!mounted) return;
      setState(() { _saving = false; _editing = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profil diperbarui!'), backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      _load();
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _data?['user'];
    final client = user?['client'];
    final username = user?['username'] ?? 'User';
    final email = user?['email'] ?? '';
    final initials = username.length >= 2 ? username.substring(0, 2).toUpperCase() : username.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(title: const Text('Profil'), backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white,
        actions: [
          if (!_editing) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _editing = true)),
        ]),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
            // Avatar
            Container(width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.accentGold, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.accentGold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Center(child: Text(initials, style: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)))),
            const SizedBox(height: 12),
            Text(username, style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
            Text(email, style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textGray)),
            const SizedBox(height: 24),

            // Info card
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
              child: Column(children: [
                if (!_editing) ...[
                  _infoRow(Icons.monitor_weight_outlined, 'Berat Badan', '${client?['bb'] ?? '-'} kg'),
                  const Divider(height: 24),
                  _infoRow(Icons.height, 'Tinggi Badan', '${client?['tb'] ?? '-'} cm'),
                  const Divider(height: 24),
                  _infoRow(Icons.cake_outlined, 'Umur', '${client?['umur'] ?? '-'} tahun'),
                  const Divider(height: 24),
                  _infoRow(Icons.person_outline, 'Gender', client?['gender'] == 'L' ? 'Laki-laki' : client?['gender'] == 'P' ? 'Perempuan' : '-'),
                ] else ...[
                  _editField('Berat Badan (kg)', _bbC, Icons.monitor_weight_outlined),
                  const SizedBox(height: 14),
                  _editField('Tinggi Badan (cm)', _tbC, Icons.height),
                  const SizedBox(height: 14),
                  _editField('Umur', _umurC, Icons.cake_outlined),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => setState(() => _editing = false),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textGray,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: Text('Batal', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Simpan', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700)))),
                  ]),
                ],
              ])),
            const SizedBox(height: 24),

            // Logout
            SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: Text('Logout', style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            )),
          ])),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textLightGray)),
        Text(value, style: GoogleFonts.quicksand(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
      ])),
    ]);
  }

  Widget _editField(String label, TextEditingController c, IconData icon) {
    return TextField(controller: c, keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.textLightGray)));
  }
}
