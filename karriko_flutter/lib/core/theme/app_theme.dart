import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Website design tokens (globals.css)
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF5F625F);
  static const line = Color(0xFFD8D8D2);
  static const paper = Color(0xFFF7F7F2);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFFE3342F);
  static const accentDark = Color(0xFFB91F1A);
  static const green = Color(0xFF526B58);
  static const audienceBeige = Color(0xFFF1F0E8);

  // Aliases used across existing screens
  static const primary = accent;
  static const primaryDark = accentDark;
  static const primaryLight = Color(0xFFFEE2E1);
  static const background = paper;
  static const textPrimary = ink;
  static const textSecondary = muted;
  static const textMuted = muted;
  static const border = line;
  static const darkGreen = green;
  static const lightGreen = audienceBeige;
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x12000000),
    blurRadius: 18,
    offset: Offset(0, 4),
  );
}

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 0.92,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 0.96,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 17,
        color: AppColors.ink,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.muted,
        height: 1.55,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.muted,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: 0.11 * 12,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.paper,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.ink, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: const Color(0xFF8C8E88),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.muted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.ink,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
