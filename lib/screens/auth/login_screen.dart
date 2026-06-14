import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/cm_background.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedRole = 1; // 1 = Client, 2 = Trainer
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validasi berurutan: username dulu, baru password (tidak dua-duanya sekaligus).
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });
    if (_username.text.trim().isEmpty) {
      setState(() => _usernameError = 'Username wajib diisi');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _passwordError = 'Password wajib diisi');
      return;
    }
    FocusScope.of(context).unfocus();
    // Error dari server (mis. "Username atau password salah.") ditampilkan
    // inline lewat auth.error di bawah tombol.
    await context.read<AuthProvider>().login(
          _username.text.trim(),
          _password.text,
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: CmBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - 32),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: size.width),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            color: CmColors.authPanelGreen,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.3,
                                    child: Image.asset(
                                      'assets/images/group-54.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Image.asset(
                                  'assets/images/mascot-register.png',
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/images/logo-warna.png',
                                    height: 56,
                                  ),
                                  const SizedBox(height: 16),
                                  // ── Role Toggle ──────────────────────
                                  Container(
                                    decoration: BoxDecoration(
                                      color: CmColors.backgroundCream,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Row(
                                      children: [
                                        _roleTab('Client', 1),
                                        _roleTab('Trainer', 2),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _username,
                                    onChanged: (_) {
                                      context.read<AuthProvider>().clearError();
                                      if (_usernameError != null) {
                                        setState(() => _usernameError = null);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      hintText: 'Username',
                                      errorText: _usernameError,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _password,
                                    obscureText: true,
                                    onChanged: (_) {
                                      context.read<AuthProvider>().clearError();
                                      if (_passwordError != null) {
                                        setState(() => _passwordError = null);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Password',
                                      errorText: _passwordError,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Pesan error dari server (login gagal), tampil inline
                                  if (auth.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        auth.error!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
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
                                          : Text('Login sebagai ${_selectedRole == 1 ? 'Client' : 'Trainer'}'),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    ),
                                    child: const Text(
                                      'Belum punya akun? Register',
                                      style: TextStyle(
                                        color: Color(0xFF2E4F2A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTab(String label, int role) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? CmColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : CmColors.primaryGreen,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
