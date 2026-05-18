import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF2E471F);
  static const Color darkGreen = Color(0xFF1E3A16);
  static const Color lightGreen = Color(0xFF3D6628);
  static const Color accentGold = Color(0xFFF5A623);
  static const Color backgroundBeige = Color(0xFFEFE6D2);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF2E471F);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textLightGray = Color(0xFF9CA3AF);
  static const Color borderGray = Color(0xFFE5E7EB);

  // Macro colors
  static const Color proteinBlue = Color(0xFF3B82F6);
  static const Color carboGreen = Color(0xFF22C55E);
  static const Color fatOrange = Color(0xFFF97316);

  // BMI colors
  static const Color bmiUnderweight = Color(0xFF3B82F6);
  static const Color bmiNormal = Color(0xFF22C55E);
  static const Color bmiOverweight = Color(0xFFEAB308);
  static const Color bmiObese = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundBeige,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.accentGold,
        surface: AppColors.backgroundBeige,
      ),
      textTheme: GoogleFonts.quicksandTextTheme().copyWith(
        headlineLarge: GoogleFonts.raleway(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        headlineMedium: GoogleFonts.raleway(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineSmall: GoogleFonts.raleway(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleLarge: GoogleFonts.raleway(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textGray,
        ),
        bodySmall: GoogleFonts.quicksand(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textLightGray,
        ),
        labelLarge: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          textStyle: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGray, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textGray,
        ),
        hintStyle: GoogleFonts.quicksand(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textLightGray,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.raleway(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: AppColors.primaryGreen,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
