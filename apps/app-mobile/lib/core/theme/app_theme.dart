import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const primary = Color(0xFF4F46E5);
    const secondary = Color(0xFFF97316);
    const surface = Color(0xFFF5F7FF);
    const surfaceBright = Color(0xFFFFFFFF);
    const ink = Color(0xFF1E1B4B);
    const muted = Color(0xFF5B5F87);
    const border = Color(0xFFD9DEFF);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: surface,
      onSurface: ink,
    );

    final textTheme = GoogleFonts.nunitoTextTheme().copyWith(
      headlineLarge: GoogleFonts.fredoka(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 0.98,
      ),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.02,
      ),
      headlineSmall: GoogleFonts.fredoka(
        fontSize: 23,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleLarge: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: ink,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: muted,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: muted,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surfaceBright,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        backgroundColor: const Color(0xFFE8EBFF),
        labelStyle: textTheme.bodySmall?.copyWith(color: ink),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceBright,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        prefixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary.withValues(alpha: 0.35);
          }
          return const Color(0xFFD7DBF4);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceBright,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      extensions: const [
        AppPalette(
          primarySoft: Color(0xFFE7E8FF),
          secondarySoft: Color(0xFFFFE6D6),
          tertiarySoft: Color(0xFFDDF8FF),
          successSoft: Color(0xFFE4F9EC),
          spotlight: Color(0xFFFFE27A),
        ),
      ],
    );
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primarySoft,
    required this.secondarySoft,
    required this.tertiarySoft,
    required this.successSoft,
    required this.spotlight,
  });

  final Color primarySoft;
  final Color secondarySoft;
  final Color tertiarySoft;
  final Color successSoft;
  final Color spotlight;

  @override
  AppPalette copyWith({
    Color? primarySoft,
    Color? secondarySoft,
    Color? tertiarySoft,
    Color? successSoft,
    Color? spotlight,
  }) {
    return AppPalette(
      primarySoft: primarySoft ?? this.primarySoft,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      tertiarySoft: tertiarySoft ?? this.tertiarySoft,
      successSoft: successSoft ?? this.successSoft,
      spotlight: spotlight ?? this.spotlight,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      secondarySoft: Color.lerp(secondarySoft, other.secondarySoft, t) ?? secondarySoft,
      tertiarySoft: Color.lerp(tertiarySoft, other.tertiarySoft, t) ?? tertiarySoft,
      successSoft: Color.lerp(successSoft, other.successSoft, t) ?? successSoft,
      spotlight: Color.lerp(spotlight, other.spotlight, t) ?? spotlight,
    );
  }
}
