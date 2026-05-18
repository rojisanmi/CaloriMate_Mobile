import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age = TextEditingController();
  String _gender = 'L';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose(); _email.dispose(); _password.dispose();
    _height.dispose(); _weight.dispose(); _age.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_username.text.isEmpty || _email.text.isEmpty || _password.text.isEmpty ||
        _height.text.isEmpty || _weight.text.isEmpty || _age.text.isEmpty) {
      setState(() => _error = 'Semua field harus diisi');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/register/client'),
        headers: {'Accept': 'application/json'},
        body: {
          'username': _username.text, 'email': _email.text,
          'password': _password.text, 'tinggi_badan': _height.text,
          'berat_badan': _weight.text, 'gender': _gender, 'umur': _age.text,
        },
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
      } else {
        setState(() { _loading = false;
          if (data['errors'] != null) {
            final e = data['errors'] as Map<String, dynamic>;
            _error = e.values.first is List ? (e.values.first as List).first.toString() : e.values.first.toString();
          } else { _error = data['message'] ?? 'Registrasi gagal'; }
        });
      }
    } catch (e) {
      setState(() { _loading = false; _error = 'Kesalahan koneksi'; });
    }
  }

  Widget _field(String label, TextEditingController c, {TextInputType? type, IconData? icon, bool obs = false, Widget? suf}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
      const SizedBox(height: 6),
      TextField(controller: c, keyboardType: type, obscureText: obs,
        decoration: InputDecoration(hintText: label, prefixIcon: icon != null ? Icon(icon, color: AppColors.textLightGray) : null, suffixIcon: suf)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.backgroundBeige, body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
          child: const Icon(Icons.local_fire_department_rounded, color: AppColors.accentGold, size: 36)),
        const SizedBox(height: 12),
        Text('CaloriMate', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4))]),
          child: Column(children: [
            Text('Register Client', style: GoogleFonts.raleway(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
            const SizedBox(height: 20),
            if (_error != null) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Row(children: [Icon(Icons.error_outline, color: Colors.red.shade700, size: 18), const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w600)))])),
            _field('Username', _username, icon: Icons.person_outline),
            const SizedBox(height: 14),
            _field('Email', _email, type: TextInputType.emailAddress, icon: Icons.email_outlined),
            const SizedBox(height: 14),
            _field('Password', _password, icon: Icons.lock_outline, obs: _obscure,
              suf: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textLightGray),
                onPressed: () => setState(() => _obscure = !_obscure))),
            const SizedBox(height: 14),
            _field('Tinggi Badan (cm)', _height, type: TextInputType.number, icon: Icons.height),
            const SizedBox(height: 14),
            _field('Berat Badan (kg)', _weight, type: TextInputType.number, icon: Icons.monitor_weight_outlined),
            const SizedBox(height: 14),
            _field('Umur', _age, type: TextInputType.number, icon: Icons.cake_outlined),
            const SizedBox(height: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Jenis Kelamin', style: GoogleFonts.quicksand(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: GestureDetector(onTap: () => setState(() => _gender = 'L'),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: _gender == 'L' ? AppColors.primaryGreen : Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gender == 'L' ? AppColors.primaryGreen : AppColors.borderGray, width: 2)),
                    child: Center(child: Text('Laki-laki', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: _gender == 'L' ? Colors.white : AppColors.textGray)))))),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(onTap: () => setState(() => _gender = 'P'),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: _gender == 'P' ? AppColors.primaryGreen : Colors.white, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _gender == 'P' ? AppColors.primaryGreen : AppColors.borderGray, width: 2)),
                    child: Center(child: Text('Perempuan', style: GoogleFonts.quicksand(fontWeight: FontWeight.w700, color: _gender == 'P' ? Colors.white : AppColors.textGray)))))),
              ]),
            ]),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : Text('Register', style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)))),
          ])),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Sudah punya akun? ', style: GoogleFonts.quicksand(fontSize: 14, color: AppColors.textGray)),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Text('Login', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen))),
        ]),
      ])))));
  }
}
