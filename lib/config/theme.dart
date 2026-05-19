import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CmColors {
  static const primaryGreen = Color(0xFF2E471F);
  static const primaryGreenHover = Color(0xFF3D6628);
  static const accentOrange = Color(0xFFF5A623);
  static const backgroundCream = Color(0xFFEFE6D2);
  static const authPanelGreen = Color(0xFF2D5016);
  static const protein = Color(0xFF3B82F6);
  static const carbs = Color(0xFF22C55E);
  static const fat = Color(0xFFF97316);
  static const netCalories = Color(0xFF3B82F6);
}

class CmTheme {
  static ThemeData get light {
    final quicksand = GoogleFonts.quicksandTextTheme();
    final raleway = GoogleFonts.raleway();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: CmColors.backgroundCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CmColors.primaryGreen,
        primary: CmColors.primaryGreen,
        secondary: CmColors.accentOrange,
        surface: Colors.white,
      ),
      textTheme: quicksand.copyWith(
        headlineMedium: raleway.copyWith(
          fontWeight: FontWeight.w800,
          color: CmColors.primaryGreen,
        ),
        headlineSmall: raleway.copyWith(
          fontWeight: FontWeight.w700,
          color: CmColors.primaryGreen,
        ),
        titleLarge: raleway.copyWith(
          fontWeight: FontWeight.w700,
          color: CmColors.primaryGreen,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CmColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CmColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CmColors.primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF2E4F2A),
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
