import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Inter, Version 4.1, als Asset eingebettet (siehe pubspec.yaml). Alle
/// Staerken zeigen bewusst auf Inter Regular; die FontWeight-Angaben unten
/// bleiben stehen, wirken aber erst, wenn echte Schnitte eingetragen sind.
/// Frueher kam die Schrift ueber google_fonts zur Laufzeit von Google; damit
/// ging die IP jedes Besuchers an Google (LG Muenchen I, 3 O 17493/20).
class AppFonts {
  static const family = 'Inter';
}

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
}

/// Corner radii used across the app.
class AppRadius {
  AppRadius._();

  /// Standard corner radius for all buttons.
  static const double button = 10;
}

/// Swiss-style layout constants: a fixed grid measure and a consistent spacing
/// scale for edge gutters. Content is capped to a readable width and centered,
/// with generous, uniform margins that scale with the viewport.
class AppLayout {
  AppLayout._();

  /// Maximum measure the content column is allowed to occupy.
  static const double maxContentWidth = 1200;

  /// Spacing scale — use these values exclusively for gaps and margins.
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  /// Horizontal edge gutter for the given viewport width, drawn from the scale.
  static double gutter(double width) =>
      width >= 1024 ? s64 : (width >= 600 ? s48 : s24);
}

/// Full-bleed band whose inner content is capped to [AppLayout.maxContentWidth],
/// centered, and padded with the responsive edge gutter. Keeps hairline rules
/// spanning the full width while the content stays on a readable measure.
class ContentBand extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const ContentBand({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutter(MediaQuery.of(context).size.width);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter).add(padding),
          child: child,
        ),
      ),
    );
  }
}

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 0.92,
        letterSpacing: -1,
      ),
      displayMedium: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 0.96,
        letterSpacing: -0.5,
      ),
      displaySmall: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1,
      ),
      headlineLarge: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        height: 1,
      ),
      headlineMedium: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      headlineSmall: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 17,
        color: AppColors.ink,
        height: 1.55,
      ),
      bodyMedium: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 15,
        color: AppColors.muted,
        height: 1.55,
      ),
      bodySmall: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 13,
        color: AppColors.muted,
        height: 1.35,
      ),
      labelLarge: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      labelMedium: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        letterSpacing: 0.11 * 12,
      ),
      labelSmall: const TextStyle(
        fontFamily: AppFonts.family,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }

  static ThemeData get light {
    // Die Schrift liegt als Asset in der App (assets/fonts/inter) und wird nicht
    // zur Laufzeit von Google geladen. Ueber ThemeData gilt sie auch fuer alle
    // Material-Texte, die unten nicht eigens gestaltet sind.
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.family,
    );
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
      // Keine Material-Welle beim Klick: Der wachsende Kreis wirkt im Browser
      // wie ein Zoom und passt nicht zur flachen Gestaltung. Hover-, Fokus-
      // und Druckfarben bleiben erhalten.
      splashFactory: NoSplash.splashFactory,
      // Im Browser wechseln Seiten ohne Animation, wie bei einer Website.
      // Flutters Standard ist dort ein Zoom-Uebergang. Die nativen Apps
      // behalten ihre Uebergaenge samt Wisch-zurueck unter iOS.
      pageTransitionsTheme: kIsWeb
          ? PageTransitionsTheme(builders: {
              for (final platform in TargetPlatform.values)
                platform: const _NoPageTransitionsBuilder(),
            })
          : base.pageTransitionsTheme,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        iconTheme: IconThemeData(color: AppColors.ink),
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.family,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: const TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 15,
          color: Color(0xFF8C8E88),
        ),
        labelStyle: TextStyle(
          fontFamily: AppFonts.family,
          fontSize: 14,
          color: AppColors.muted,
        ),
      ),
      // Der Datumswaehler kommt sonst in Material-Standardoptik: runde Ecken,
      // eingefaerbte Flaeche. Hier traegt er dieselbe Sprache wie der Rest.
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.ink,
        headerForegroundColor: AppColors.paper,
        dividerColor: AppColors.line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: AppColors.ink, width: 2),
        ),
        todayBorder: BorderSide(color: AppColors.ink),
        dayShape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.ink,
        labelStyle: TextStyle(
            fontFamily: AppFonts.family,
            fontSize: 12,
            fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: BorderSide(color: AppColors.line),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}

/// Seitenwechsel ohne Animation: Die neue Seite steht sofort da.
class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
