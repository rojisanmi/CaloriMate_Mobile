import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../widgets/cm_background.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final res = await _api.get('/trainer/dashboard');
      final data = res.data;
      if (data is Map) {
        setState(() {
          _data = Map<String, dynamic>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _errorMessage = "Format data API tidak valid.";
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      setState(() {
        _loading = false;
        _errorMessage = "Gagal memuat: Pastikan IP API terhubung.\nDetail: $e";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Pastikan Laptop & HP di WiFi yang sama! ($e)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EB), // Warna background persis Web
      body: CmBackground(
        child: RefreshIndicator(
          color: CmColors.accentOrange,
          onRefresh: _load,
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: CmColors.primaryGreen),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 16),
                      // Header
                      _buildHeader(auth),
                      const SizedBox(height: 24),

                      // Error message jika koneksi gagal (Tampil menonjol)
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stats cards (2 Kolom)
                      _buildStatsCards(),
                      const SizedBox(height: 16),

                      // Activity chart (Full Width)
                      _buildActivityChart(),
                      const SizedBox(height: 16),

                      // Top foods (Full Width)
                      _buildTopFoods(),
                      const SizedBox(height: 16),

                      // Top programs (Ditumpuk Vertikal)
                      _buildTopPrograms(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Halo, ',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E471F),
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: auth.displayName.isNotEmpty ? '${auth.displayName}!' : 'Trainer!',
                      style: const TextStyle(color: Color(0xFFF5A623)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Berikut ringkasan aktivitas platform CaloriMate.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        // Logo atau Avatar seperti di Web
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFF5A623),
          child: _buildAvatarImage(auth),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(AuthProvider auth) {
    final serverPath = auth.trainer?['photo_url']?.toString() ?? auth.trainer?['photo_path']?.toString();
    if (serverPath != null && serverPath.isNotEmpty) {
      final url = serverPath.startsWith('http') ? serverPath : '${ApiConfig.storageUrl.replaceAll(RegExp(r'/$'), '')}/${serverPath.replaceFirst(RegExp(r'^/'), '')}';
      return ClipOval(
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildAvatarInitials(auth),
        ),
      );
    }
    return _buildAvatarInitials(auth);
  }

  Widget _buildAvatarInitials(AuthProvider auth) {
    return Text(
      auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'T',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalClients = _data['total_clients'] ?? 0;
    final activeClients = _data['active_clients'] ?? 0;
    final totalFoods = _data['total_foods'] ?? 0;
    final totalPrograms = _data['total_programs'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.groups_rounded,
                iconColor: const Color(0xFF2E471F), // Hijau tua Web
                value: '$totalClients',
                label: 'Total Client',
                sublabel: 'terdaftar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFFF5A623), // Orange Web
                value: '$activeClients',
                label: 'Client Aktif 7 Hari',
                sublabel: 'unik dengan aktivitas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.grid_view_rounded,
                iconColor: const Color(0xFF3B82F6), // Biru Web
                value: '$totalFoods',
                label: 'Total Makanan',
                sublabel: 'di database',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF22C55E), // Hijau Terang Web
                value: '$totalPrograms',
                label: 'Total Program',
                sublabel: 'program latihan',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    // Selalu render card ini walaupun kosong agar layout konsisten
    final chart = _data['activity_chart'];
    final labels = (chart?['labels'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final values = (chart?['values'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];

    final hasData = labels.isNotEmpty && values.isNotEmpty;
    final maxVal = hasData ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final maxY = (maxVal == 0 ? 5 : (maxVal + 1)).ceilToDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Client Aktif per Hari',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E471F),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '7 hari terakhir — jumlah client unik yang mencatat aktivitas',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: !hasData
                ? const Center(
                    child: Text('Belum ada data aktivitas.',
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)))
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 6,
                          getTooltipItem: (group, gIdx, rod, rIdx) {
                            return BarTooltipItem(
                              '${rod.toY.toInt()} client aktif',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  labels[idx],
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value == value.roundToDouble() && value >= 0) {
                                return Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.black.withValues(alpha: 0.04),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(values.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              color: const Color(0xFFF5A623).withValues(alpha: 0.8), // Orange with opacity
                              width: 32, // Lebar chart menyesuaikan
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFoods() {
    final topFoodsData = _data['top_foods'];
    List<Map<String, dynamic>> foods = [];
    
    if (topFoodsData is List) {
      foods = topFoodsData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final maxFreq = foods.isEmpty 
        ? 0.0 
        : foods.map((f) => (f['frequency'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Makanan Terpopuler',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E471F),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Paling sering dicatat oleh client',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 16),
          
          if (foods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada data konsumsi.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            )
          else
            ...List.generate(foods.length, (i) {
              final food = foods[i];
              final name = food['name']?.toString() ?? '';
              final freq = (food['frequency'] as num?)?.toInt() ?? 0;
              final pct = maxFreq > 0 ? (freq / maxFreq) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E471F),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$freq×',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF3F4F6),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopPrograms() {
    final topProgramsData = _data['top_programs'];
    List<Map<String, dynamic>> programs = [];

    if (topProgramsData is List) {
      programs = topProgramsData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Program Latihan Terpopuler',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E471F),
              fontSize: 14,
            ),
          ),
        ),
        if (programs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('Belum ada data program latihan.',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          )
        else
          ...List.generate(programs.length, (i) {
            final p = programs[i];
            final name = p['name']?.toString() ?? '';
            final difficulty = p['difficulty']?.toString().toLowerCase() ?? '';
            final usageCount = (p['usage_count'] as num?)?.toInt() ?? 0;
            final medals = ['🥇', '🥈', '🥉'];

            Color bgBadge;
            Color textBadge;
            String labelBadge;

            if (['low', 'rendah', 'beginner', 'pemula'].contains(difficulty)) {
              bgBadge = const Color(0xFFDCFCE7);
              textBadge = const Color(0xFF15803D);
              labelBadge = 'Mudah';
            } else if (['high', 'tinggi', 'advanced', 'lanjutan'].contains(difficulty)) {
              bgBadge = const Color(0xFFFEE2E2);
              textBadge = const Color(0xFFB91C1C);
              labelBadge = 'Sulit';
            } else {
              bgBadge = const Color(0xFFFEF9C3);
              textBadge = const Color(0xFFA16207);
              labelBadge = 'Sedang';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i < medals.length ? medals[i] : '🏅',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E471F),
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bgBadge,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  labelBadge,
                                  style: TextStyle(
                                    color: textBadge,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$usageCount× digunakan',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E471F),
              fontSize: 12,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
