import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _tb = TextEditingController();
  final _bb = TextEditingController();
  final _umur = TextEditingController();
  String _gender = 'L';

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _tb.dispose();
    _bb.dispose();
    _umur.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _username.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      tb: double.parse(_tb.text),
      bb: double.parse(_bb.text),
      gender: _gender,
      umur: int.parse(_umur.text),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registrasi gagal'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else if (ok && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Client'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CmBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CmCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset('assets/images/logo.png', height: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Daftar Akun Baru',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _field(_username, 'Username', maxLen: 20),
                    const SizedBox(height: 12),
                    _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _field(_password, 'Password', obscure: true),
                    const SizedBox(height: 12),
                    _field(_tb, 'Tinggi Badan (cm)', keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    _field(_bb, 'Berat Badan (kg)', keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    _field(_umur, 'Umur', keyboard: TextInputType.number),
                    const SizedBox(height: 12),
                    const Text('Jenis Kelamin',
                        style: TextStyle(fontWeight: FontWeight.w600, color: CmColors.primaryGreen)),
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: auth.loading ? null : _submit,
                      child: auth.loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
    int? maxLen,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      maxLength: maxLen,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
    );
  }
}