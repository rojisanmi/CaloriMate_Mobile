import 'package:flutter/material.dart';

class CmProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  final Color trackColor;
  final double height;

  const CmProgressBar({
    super.key,
    required this.percent,
    required this.color,
    this.trackColor = const Color(0xFFF3F4F6),
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: (percent / 100).clamp(0.0, 1.0),
          backgroundColor: trackColor,
          color: color,
          minHeight: height,
        ),
      ),
    );
  }
}
