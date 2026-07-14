import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ─── Brand Core ───────────────────────────────────────────────────────────
  static const Color primaryBurgundy = Color(0xFF6B0F2A);
  static const Color primaryDarkBurgundy = Color(0xFF3D0717);
  static const Color primaryMidBurgundy = Color(0xFF8C1A3A);

  // ─── Metallic Accents ─────────────────────────────────────────────────────
  static const Color accentRoseGold = Color(0xFFD4956A);
  static const Color accentGold = Color(0xFFE8B86D);
  static const Color accentPeach = Color(0xFFF2C4A0);

  // ─── Surfaces ─────────────────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFAF7F5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardCream = Color(0xFFF7F3EF);
  static const Color cardElevated = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassDark = Color(0x33000000);

  // ─── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1219);
  static const Color textSecondary = Color(0xFF7C6E7A);
  static const Color textMuted = Color(0xFFB8A8B5);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFAF7F5);

  // ─── Status ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1B7A4A);
  static const Color warning = Color(0xFFC07A1A);
  static const Color error = Color(0xFFB82020);
  static const Color info = Color(0xFF1A6FA8);
  static const Color verificationBadge = Color(0xFF3B82F6);

  // ─── Borders ──────────────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFEDE6E2);
  static const Color borderMedium = Color(0xFFD4C8C2);

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8C1A3A), Color(0xFF3D0717)],
  );

  static const LinearGradient premiumBurgundyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9E1B3E), Color(0xFF380512)],
  );

  static const LinearGradient roseGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7D5C4), Color(0xFFE2A28A), Color(0xFFC57A68)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 1.0],
    colors: [Colors.transparent, Color(0x44000000), Color(0xDD000000)],
  );

  static const RadialGradient backgroundRadial = RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.4,
    colors: [Color(0xFF8C1A3A), Color(0xFF3D0717), Color(0xFF1A0209)],
    stops: [0.0, 0.6, 1.0],
  );
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double s = 8.0;
  static const double m = 16.0;
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppRadius {
  static const double xs = 6.0;
  static const double s = 10.0;
  static const double m = 14.0;
  static const double l = 20.0;
  static const double xl = 28.0;
  static const double xxl = 36.0;
  static const double circular = 999.0;
}

class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF6B0F2A).withOpacity(0.08),
          blurRadius: 16.0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF1A1219).withOpacity(0.06),
          blurRadius: 24.0,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: const Color(0xFF1A1219).withOpacity(0.03),
          blurRadius: 6.0,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get button => [
        BoxShadow(
          color: const Color(0xFF6B0F2A).withOpacity(0.35),
          blurRadius: 20.0,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppTheme {
  // Premium Serif moment (Cormorant Garamond SemiBold)
  static TextStyle serifHeadline({required double fontSize, Color? color}) {
    return GoogleFonts.cormorantGaramond(
      fontSize: fontSize,
      fontWeight: FontWeight.w600, // SemiBold
      color: color ?? AppColors.primaryBurgundy,
      height: 1.15,
    );
  }

  // Modern Sans moment (Plus Jakarta Sans)
  static TextStyle sansText({required double fontSize, required FontWeight weight, Color? color, double? height}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final plusJakartaSansTextTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32.0,
        fontWeight: FontWeight.w700, // Hero onboarding headline
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 26.0,
        fontWeight: FontWeight.w600, // Main page title
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22.0,
        fontWeight: FontWeight.w700, // Profile name
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 18.0,
        fontWeight: FontWeight.w600, // Section heading
        color: AppColors.textPrimary,
        height: 1.35,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16.0,
        fontWeight: FontWeight.w600, // Button text
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16.0,
        fontWeight: FontWeight.w400, // Body text
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14.0,
        fontWeight: FontWeight.w500, // Form labels & secondary
        color: AppColors.textSecondary,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w400, // Captions & metadata
        color: AppColors.textMuted,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBurgundy,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBurgundy,
        secondary: AppColors.accentRoseGold,
        surface: AppColors.surfaceWhite,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: plusJakartaSansTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardElevated,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.l)),
          side: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBurgundy,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(56.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16.0,
            fontWeight: FontWeight.w600, // Button labels
            letterSpacing: 0.2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceWhite,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBurgundy,
          side: const BorderSide(color: AppColors.primaryBurgundy, width: 1.5),
          minimumSize: const Size.fromHeight(56.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.circular),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 17.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.primaryBurgundy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 14.0, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 14.0, fontWeight: FontWeight.w400),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        space: 1,
        thickness: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.borderLight,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        selectedItemColor: AppColors.primaryBurgundy,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.0, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.0, fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
