import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// ===========================================================
/// NANCY
/// Sistema Integral de Inscripciones
/// -----------------------------------------------------------
/// Tema oficial de la aplicación.
/// ===========================================================
class AppTheme {
  AppTheme._();

  // ===========================================================
  // TEMA CLARO
  // ===========================================================

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      secondary: AppColors.primaryGreen,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.background,

      fontFamily: GoogleFonts.poppins().fontFamily,

      textTheme: TextTheme(
        displayLarge: AppTextStyles.headlineLarge,
        displayMedium: AppTextStyles.headlineMedium,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        hintStyle: AppTextStyles.bodySmall,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  // ===========================================================
  // TEMA OSCURO
  // ===========================================================

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF5BA9F5),
      secondary: const Color(0xFF66BB8A),
      surface: const Color(0xFF18212B),
      error: const Color(0xFFFF7676),
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: const Color(0xFF111820),

      fontFamily: GoogleFonts.poppins().fontFamily,

      textTheme: TextTheme(
        displayLarge: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
        displayMedium: AppTextStyles.headlineMedium.copyWith(
          color: Colors.white,
        ),
        titleLarge: AppTextStyles.title.copyWith(color: Colors.white),
        titleMedium: AppTextStyles.subtitle.copyWith(
          color: const Color(0xFFD4DCE5),
        ),
        bodyLarge: AppTextStyles.body.copyWith(color: const Color(0xFFD4DCE5)),
        bodyMedium: AppTextStyles.body.copyWith(color: const Color(0xFFD4DCE5)),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: const Color(0xFFAAB7C5),
        ),
        labelLarge: AppTextStyles.button.copyWith(color: Colors.white),
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Color(0xFF18212B),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF18212B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF3B91DD),
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          foregroundColor: const Color(0xFF5BA9F5),
          side: const BorderSide(color: Color(0xFF5BA9F5)),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2935),

        hintStyle: const TextStyle(color: Color(0xFF8796A6)),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: Color(0xFF344252)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: Color(0xFF5BA9F5), width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: Color(0xFFFF7676)),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: Color(0xFFFF7676), width: 2),
        ),
      ),
    );
  }
}
