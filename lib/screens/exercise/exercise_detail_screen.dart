import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';
import '../../widgets/cm_card.dart';
import 'active_workout_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final int programId;
  final String title;

  const ExerciseDetailScreen({
    super.key,
    required this.programId,
    required this.title,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  bool _starting = false;
  Map<String, dynamic>? _program;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/client/exercise/${widget.programId}');
      setState(() {
        _program = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_program == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Program', style: TextStyle(color: CmColors.primaryGreen, fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin memulai program latihan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: CmColors.primaryGreen, foregroundColor: Colors.white),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(program: _program!),
      ),
    );

    if (completed == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: CmColors.primaryGreen))
          : CmBackground(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _program?['name']?.toString() ?? widget.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (_program?['type'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tipe: ${_program!['type']}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                        if (_program?['difficulty'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tingkat: ${_program!['difficulty']}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daftar Latihan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...((_program?['items'] as List?) ?? []).map((item) {
                    final m = item as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CmCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2EAD3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.sports_gymnastics,
                                  color: CmColors.primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m['exercise_name']?.toString() ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    [
                                      if (m['duration_minutes'] != null)
                                        '${m['duration_minutes']} menit',
                                      if (m['intensity_level'] != null)
                                        m['intensity_level'].toString(),
                                    ].join(' · '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _starting ? null : _start,
                      icon: _starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_starting ? 'Memulai...' : 'Mulai Program'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
