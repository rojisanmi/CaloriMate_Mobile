class BmiInfo {
  final double bmi;
  final String category;
  final int bgColor;
  final int textColor;
  final int barColor;

  const BmiInfo({
    required this.bmi,
    required this.category,
    required this.bgColor,
    required this.textColor,
    required this.barColor,
  });
}

BmiInfo? calculateBmi(double? bb, double? tb) {
  if (bb == null || tb == null || tb <= 0) return null;
  final heightM = tb / 100;
  final bmi = bb / (heightM * heightM);

  String category;
  int bg, text, bar;
  if (bmi < 18.5) {
    category = 'Underweight';
    bg = 0xFFDBEAFE;
    text = 0xFF1D4ED8;
    bar = 0xFF3B82F6;
  } else if (bmi < 25) {
    category = 'Normal';
    bg = 0xFFDCFCE7;
    text = 0xFF15803D;
    bar = 0xFF22C55E;
  } else if (bmi < 30) {
    category = 'Overweight';
    bg = 0xFFFEF9C3;
    text = 0xFFA16207;
    bar = 0xFFEAB308;
  } else {
    category = 'Obese';
    bg = 0xFFFEE2E2;
    text = 0xFFB91C1C;
    bar = 0xFFEF4444;
  }

  return BmiInfo(
    bmi: double.parse(bmi.toStringAsFixed(1)),
    category: category,
    bgColor: bg,
    textColor: text,
    barColor: bar,
  );
}
