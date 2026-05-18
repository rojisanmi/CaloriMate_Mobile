import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.get('/client/profile');
      print('DEBUG: Profile Data: $data');
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (e) {
      print('DEBUG: Profile Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _bmi {
    final client = _profile?['user']?['client'];
    if (client == null) return null;
    final bb = double.tryParse(client['bb']?.toString() ?? '') ?? 0.0;
    final tb = double.tryParse(client['tb']?.toString() ?? '') ?? 0.0;
    if (bb <= 0 || tb <= 0) return null;
    return bb / ((tb / 100) * (tb / 100));
  }

  String get _bmiCategory {
    final bmi = _bmi;
    if (bmi == null) return '';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    return switch (_bmiCategory) {
      'Underweight' => AppColors.bmiUnderweight,
      'Normal' => AppColors.bmiNormal,
      'Overweight' => AppColors.bmiOverweight,
      'Obese' => AppColors.bmiObese,
      _ => AppColors.textGray,
    };
  }

  Color get _bmiBgColor {
    return switch (_bmiCategory) {
      'Underweight' => const Color(0xFFDBEAFE),
      'Normal' => const Color(0xFFDCFCE7),
      'Overweight' => const Color(0xFFFEF9C3),
      'Obese' => const Color(0xFFFEE2E2),
      _ => Colors.grey.shade100,
    };
  }

  String get _username => _profile?['user']?['username'] ?? 'User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
            : RefreshIndicator(
                color: AppColors.primaryGreen,
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Halo,', style: GoogleFonts.raleway(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                        Text(_username, style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.accentGold)),
                      ])),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadProfile()),
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.accentGold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                          ),
                          child: Center(child: Text(_username.substring(0, _username.length >= 2 ? 2 : 1).toUpperCase(),
                            style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryGreen))),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('Siap pantau kalori hari ini?', style: GoogleFonts.quicksand(fontSize: 16, color: AppColors.textGray)),
                    const SizedBox(height: 20),

                    // BMI Card
                    if (_bmi != null) _buildBmiCard() else _buildNoBmiCard(),
                    const SizedBox(height: 24),

                    // Quick Nav
                    Text('Menu', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2, shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12, mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _quickNav(Icons.menu_book_rounded, 'Diary', 'Catat makanan', 1),
                        _quickNav(Icons.flash_on_rounded, 'Exercise', 'Program latihan', 2),
                        _quickNav(Icons.bar_chart_rounded, 'Statistik', 'Data harian', 3),
                        _quickNav(Icons.history_rounded, 'Riwayat', 'Pola kalori', 4),
                      ],
                    ),
                  ]),
                ),
              ),
      ),
    );
  }

  Widget _buildBmiCard() {
    final bmi = _bmi!;
    final pct = ((bmi - 10) / 30).clamp(0.0, 1.0);
    final client = _profile?['user']?['client'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bmiBgColor, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _bmiColor.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(bmi.toStringAsFixed(1), style: GoogleFonts.raleway(fontSize: 44, fontWeight: FontWeight.w800, color: _bmiColor)),
          Text(_bmiCategory, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: _bmiColor)),
        ]),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BODY MASS INDEX', style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _bmiColor.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: Colors.black.withValues(alpha: 0.08), color: _bmiColor)),
          const SizedBox(height: 6),
          Text('${client?['bb'] ?? '-'} kg · ${client?['tb'] ?? '-'} cm',
            style: GoogleFonts.quicksand(fontSize: 12, color: _bmiColor.withValues(alpha: 0.6))),
        ])),
      ]),
    );
  }

  Widget _buildNoBmiCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
        child: Row(children: [
          Icon(Icons.info_outline, color: AppColors.accentGold, size: 32),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BMI belum tersedia', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
            Text('Lengkapi profil kamu →', style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textGray)),
          ])),
        ]),
      ),
    );
  }

  Widget _quickNav(IconData icon, String label, String sub, int tabIndex) {
    return GestureDetector(
      onTap: () {
        // Navigate using the MainShell's bottom nav
        // This is a simple approach - the parent MainShell handles tab switching
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
          Text(sub, style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray)),
        ]),
      ),
    );
  }
}