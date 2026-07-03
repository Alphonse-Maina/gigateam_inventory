import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design language: "Night Ops" — deep navy/graphite surfaces, a single
/// electric-cyan accent (reads as "security tech" without being gimmicky),
/// amber for warnings/low-stock, red for critical/removed, green for
/// approved/added. Generous corner radii, soft elevation via layered
/// surfaces rather than heavy shadows, and a consistent 4/8/12/16/24 spacing
/// scale.
class AppColors {
  AppColors._();

  // Brand
  static const Color accent = Color(0xFF00D9FF); // electric cyan
  static const Color accentDeep = Color(0xFF0091B3);

  // Surfaces (dark)
  static const Color bgDark = Color(0xFF0B0F14);
  static const Color surfaceDark = Color(0xFF121820);
  static const Color surfaceDarkAlt = Color(0xFF1A222C);
  static const Color borderDark = Color(0xFF232C38);

  // Surfaces (light)
  static const Color bgLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightAlt = Color(0xFFEEF1F5);
  static const Color borderLight = Color(0xFFE1E6EC);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Role colors
  static const Color roleAdmin = Color(0xFF00D9FF);
  static const Color roleManager = Color(0xFFA78BFA);
  static const Color roleStaff = Color(0xFF94A3B8);

  // Category colors (CCTV / Security / Networking themed)
  static const Color catCctv = Color(0xFF00D9FF);
  static const Color catNetworking = Color(0xFFA78BFA);
  static const Color catSecurity = Color(0xFFF5A524);
  static const Color catAccessories = Color(0xFF22C55E);
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color base) {
    return GoogleFonts.interTextTheme().apply(
      bodyColor: base,
      displayColor: base,
    ).copyWith(
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        color: base,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        color: base,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        color: base,
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Color(0xFF00232B),
      secondary: AppColors.roleManager,
      onSecondary: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: Color(0xFFE6EBF0),
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      textTheme: _textTheme(const Color(0xFFE6EBF0)),
      dividerColor: AppColors.borderDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDarkAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF00232B),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE6EBF0),
          side: const BorderSide(color: AppColors.borderDark),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDarkAlt,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Color(0xFF6B7684),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedIconTheme: IconThemeData(color: AppColors.accent),
        selectedLabelTextStyle: TextStyle(color: AppColors.accent),
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: AppColors.accentDeep,
      onPrimary: Colors.white,
      secondary: AppColors.roleManager,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: Color(0xFF15202B),
      error: AppColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: _textTheme(const Color(0xFF15202B)),
      dividerColor: AppColors.borderLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLightAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accentDeep, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDeep,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
