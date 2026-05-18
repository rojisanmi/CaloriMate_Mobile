import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../services/diary_service.dart';
import '../services/api_service.dart';

class AddFoodScreen extends StatefulWidget {
  final String category;
  const AddFoodScreen({super.key, required this.category});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _foods = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    // Load initial foods on screen open
    _fetchFoods();
  }

  Future<void> _fetchFoods([String query = '']) async {
    setState(() {
      _loading = true;
    });
    try {
      final response = await ApiService.get('/client/foods?q=$query');
      if (response != null && response['data'] != null) {
        setState(() {
          _foods = response['data'] as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _foods = [];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading foods: $e');
      setState(() {
        _foods = [];
        _loading = false;
      });
    }
  }

  void _search() {
    final q = _searchController.text.trim();
    setState(() {
      _searched = q.isNotEmpty;
    });
    _fetchFoods(q);
  }

  Future<void> _addFood(Map<String, dynamic> food, int portions) async {
    try {
      final foodId = int.tryParse(food['food_id']?.toString() ?? '');
      if (foodId == null) throw Exception('Food ID tidak valid');

      await DiaryService.addFood(
        foodId: foodId,
        portions: portions,
        category: widget.category,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${food['name']} ($portions porsi) berhasil ditambahkan!'),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPortionBottomSheet(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PortionSelectorBottomSheet(
          food: food,
          categoryLabel: _categoryLabel,
          onConfirm: (portions) {
            Navigator.pop(context);
            _addFood(food, portions);
          },
        );
      },
    );
  }

  String get _categoryLabel => switch (widget.category) {
    'breakfast' => 'Sarapan',
    'lunch' => 'Makan Siang',
    'dinner' => 'Makan Malam',
    'snack' => 'Camilan',
    _ => widget.category,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: Text('Tambah $_categoryLabel', style: GoogleFonts.raleway(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Elegant Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari makanan sehat...',
                hintStyle: GoogleFonts.quicksand(color: AppColors.textLightGray),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textLightGray),
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryGreen),
                        onPressed: _search,
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (val) {
                // Instantly filter as user clears search
                if (val.isEmpty) {
                  _search();
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _searched ? 'Hasil Pencarian' : 'Rekomendasi Makanan',
              style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 10),

          // Food list container
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _foods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_food_outlined, size: 64, color: AppColors.textLightGray.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              _searched ? 'Makanan tidak ditemukan' : 'Belum ada makanan tersedia',
                              style: GoogleFonts.raleway(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textGray),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba ketik kata kunci pencarian lain.',
                              style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textLightGray),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _foods.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final food = _foods[i];
                          return _foodCard(food);
                        },
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _foodCard(Map<String, dynamic> food) {
    final calories = double.tryParse(food['calories_per_portion']?.toString() ?? '') ?? 0.0;
    final grammage = double.tryParse(food['grammage']?.toString() ?? '') ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food['name'] ?? '',
                  style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${calories.round()} kkal',
                      style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.accentGold, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '  •  ${grammage.round()} gram/porsi',
                      style: GoogleFonts.quicksand(fontSize: 12, color: AppColors.textLightGray, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showPortionBottomSheet(food),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              minimumSize: Size.zero,
            ),
            child: Text('+ Tambah', style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// Stateful Widget for Interactive Portion Selector in Bottom Sheet
class _PortionSelectorBottomSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final String categoryLabel;
  final Function(int portions) onConfirm;

  const _PortionSelectorBottomSheet({
    required this.food,
    required this.categoryLabel,
    required this.onConfirm,
  });

  @override
  State<_PortionSelectorBottomSheet> createState() => _PortionSelectorBottomSheetState();
}

class _PortionSelectorBottomSheetState extends State<_PortionSelectorBottomSheet> {
  int _portions = 1;

  @override
  Widget build(BuildContext context) {
    final name = widget.food['name'] ?? 'Makanan';
    final calPerPortion = double.tryParse(widget.food['calories_per_portion']?.toString() ?? '') ?? 0.0;
    final grammage = double.tryParse(widget.food['grammage']?.toString() ?? '') ?? 0.0;
    final protein = double.tryParse(widget.food['total_protein']?.toString() ?? '') ?? 0.0;
    final carbo = double.tryParse(widget.food['total_carbo']?.toString() ?? '') ?? 0.0;
    final fat = double.tryParse(widget.food['total_fat']?.toString() ?? '') ?? 0.0;

    final totalCal = calPerPortion * _portions;
    final totalProtein = protein * _portions;
    final totalCarbo = carbo * _portions;
    final totalFat = fat * _portions;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bottom Sheet Drag Indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 18),

          // Food Info
          Text(
            name,
            style: GoogleFonts.raleway(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${grammage.round()} gram per porsi',
            style: GoogleFonts.quicksand(fontSize: 13, color: AppColors.textLightGray, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 12),

          // Portion Count Controls
          Text(
            'Jumlah Porsi',
            style: GoogleFonts.raleway(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Decrease Button
              IconButton(
                onPressed: _portions > 1 ? () => setState(() => _portions--) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 36),
                color: _portions > 1 ? AppColors.primaryGreen : AppColors.textLightGray.withValues(alpha: 0.5),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '$_portions',
                  style: GoogleFonts.raleway(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                ),
              ),
              // Increase Button
              IconButton(
                onPressed: () => setState(() => _portions++),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 36),
                color: AppColors.primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Calories Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL KALORI',
                  style: GoogleFonts.quicksand(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textGray, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalCal.round()} kkal',
                  style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.accentGold),
                ),
                const SizedBox(height: 12),
                
                // Macros breakdown details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _macroItem('Protein', '${totalProtein.toStringAsFixed(1)}g', Colors.blue),
                    _macroItem('Karbo', '${totalCarbo.toStringAsFixed(1)}g', Colors.green),
                    _macroItem('Lemak', '${totalFat.toStringAsFixed(1)}g', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Confirm button
          ElevatedButton(
            onPressed: () => widget.onConfirm(_portions),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
            child: Text(
              'Tambahkan ke ${widget.categoryLabel}',
              style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.quicksand(fontSize: 11, color: AppColors.textLightGray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: GoogleFonts.quicksand(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
