import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> program;

  const ActiveWorkoutScreen({super.key, required this.program});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentStep = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isSaving = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<dynamic> get _items => widget.program['items'] as List? ?? [];
  Map<String, dynamic> get _currentItem => _items[_currentStep] as Map<String, dynamic>? ?? {};

  @override
  void initState() {
    super.initState();
    _initStep();
  }

  void _initStep() {
    _timer?.cancel();
    final durationMins = int.tryParse(_currentItem['duration_minutes']?.toString() ?? '0') ?? 0;
    _remainingSeconds = durationMins * 60;
    
    // For testing/fallback if duration is 0, give it at least 60 seconds
    if (_remainingSeconds == 0) _remainingSeconds = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 0) {
          _audioPlayer.play(AssetSource('audio/CM.wav'));
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<bool> _confirmAction(String title, String content, String confirmText) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: CmColors.primaryGreen, fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CmColors.primaryGreen, foregroundColor: Colors.white),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _finishProgram() async {
    setState(() => _isSaving = true);
    try {
      final response = await ApiClient.instance.post('/client/exercise/${widget.program['program_id']}/start');
      if (!mounted) return;
      final estCal = response.data['calories_burned'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selamat! Latihan Selesai! Kamu membakar ~$estCal kkal.'), backgroundColor: CmColors.primaryGreen),
      );
      Navigator.pop(context, true); // Return true to indicate completion
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan latihan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() async {
    final isLast = _currentStep == _items.length - 1;
    final confirmed = await _confirmAction(
      isLast ? 'Selesai Latihan' : 'Latihan Selanjutnya',
      isLast ? 'Apakah Anda yakin ingin mengakhiri dan menyimpan program latihan ini?' : 'Lanjut ke gerakan berikutnya?',
      isLast ? 'Selesai' : 'Lanjut',
    );
    if (!confirmed) return;

    if (!isLast) {
      setState(() => _currentStep++);
      _initStep();
    } else {
      _finishProgram();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _initStep();
    }
  }

  String get _formattedTime {
    final m = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Latihan')),
        body: const Center(child: Text('Tidak ada item latihan')),
      );
    }

    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _items.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F1),
      appBar: AppBar(
        title: Text(widget.program['name'] ?? 'Latihan', style: const TextStyle(color: Colors.white)),
        backgroundColor: CmColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: CmBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.program['name'] ?? '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CmColors.primaryGreen),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFEFE6D2), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'Latihan ${_currentStep + 1} dari ${_items.length}',
                            style: const TextStyle(fontSize: 12, color: CmColors.primaryGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nama Latihan',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentItem['exercise_name']?.toString() ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CmColors.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildBadge(Icons.timer_outlined, '${_currentItem['duration_minutes']} menit', CmColors.primaryGreen),
                        const SizedBox(width: 12),
                        _buildBadge(Icons.local_fire_department_outlined, _currentItem['intensity_level']?.toString().toUpperCase() ?? 'MEDIUM', CmColors.accentOrange),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TIPS', style: TextStyle(fontWeight: FontWeight.bold, color: CmColors.primaryGreen, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            'Fokus pada teknik yang benar dan jaga pernapasan tetap teratur selama latihan.',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Text('Sisa Waktu', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EAD3),
                              border: Border.all(color: CmColors.primaryGreen, width: 2),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Text(
                              _formattedTime,
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: CmColors.primaryGreen, letterSpacing: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      if (await _confirmAction('Batalkan Latihan', 'Apakah Anda yakin ingin membatalkan sesi latihan ini? Progress tidak akan disimpan.', 'Ya, Batalkan')) {
                        navigator.pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Batalkan'),
                  ),
                  const Spacer(),
                  if (!isFirst) ...[
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: const Text('Kembali'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: _isSaving ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CmColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isLast ? 'Selesai' : 'Selanjutnya', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
