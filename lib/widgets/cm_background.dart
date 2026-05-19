import 'package:flutter/material.dart';
import '../config/theme.dart';

class CmBackground extends StatelessWidget {
  final Widget child;

  const CmBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CmColors.backgroundCream,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CmColors.accentOrange.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CmColors.primaryGreen.withValues(alpha: 0.06),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CmColors.primaryGreen.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
