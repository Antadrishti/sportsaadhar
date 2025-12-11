import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// SportsAadhaar Typography System
/// Using Poppins as the primary font family
class AppTypography {
  AppTypography._();

  // ============== BASE FONT FAMILY ==============
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  
  // For numbers, scores, timers
  static String get fontFamilyMono => GoogleFonts.jetBrainsMono().fontFamily!;

  // ============== DISPLAY STYLES ==============
  // Large headers for splash screens, celebrations
  
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 57,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 45,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static TextStyle displaySmall = GoogleFonts.poppins(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============== HEADLINE STYLES ==============
  // Section headers, card titles
  
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static TextStyle headlineMedium = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============== TITLE STYLES ==============
  // Component titles, list headers
  
  static TextStyle titleLarge = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static TextStyle titleMedium = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.33,
  );
  
  static TextStyle titleSmall = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============== BODY STYLES ==============
  // Main content text
  
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============== LABEL STYLES ==============
  // Buttons, tags, badges
  
  static TextStyle labelLarge = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static TextStyle labelMedium = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============== SPECIAL STYLES ==============
  
  /// Score display - large numbers
  static TextStyle scoreDisplay = GoogleFonts.jetBrainsMono(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    letterSpacing: -2,
    height: 1.0,
  );
  
  /// Score display medium
  static TextStyle scoreMedium = GoogleFonts.jetBrainsMono(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    height: 1.0,
  );
  
  /// Score display small
  static TextStyle scoreSmall = GoogleFonts.jetBrainsMono(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.0,
  );
  
  /// Timer display
  static TextStyle timer = GoogleFonts.jetBrainsMono(
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: 2,
    height: 1.0,
  );
  
  /// XP/Level numbers
  static TextStyle xpNumber = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.2,
  );
  
  /// Rank number
  static TextStyle rankNumber = GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.0,
  );
  
  /// Button text
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.25,
  );
  
  /// Small button text
  static TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    height: 1.14,
  );
  
  /// Caption/hint text
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.gray500,
  );
  
  /// Overline text
  static TextStyle overline = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // ============== TEXT THEME ==============
  
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );

  // ============== HELPER METHODS ==============
  
  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
  
  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
  
  /// Get text theme for light mode
  static TextTheme lightTextTheme = TextTheme(
    displayLarge: displayLarge.copyWith(color: AppColors.lightTextPrimary),
    displayMedium: displayMedium.copyWith(color: AppColors.lightTextPrimary),
    displaySmall: displaySmall.copyWith(color: AppColors.lightTextPrimary),
    headlineLarge: headlineLarge.copyWith(color: AppColors.lightTextPrimary),
    headlineMedium: headlineMedium.copyWith(color: AppColors.lightTextPrimary),
    headlineSmall: headlineSmall.copyWith(color: AppColors.lightTextPrimary),
    titleLarge: titleLarge.copyWith(color: AppColors.lightTextPrimary),
    titleMedium: titleMedium.copyWith(color: AppColors.lightTextPrimary),
    titleSmall: titleSmall.copyWith(color: AppColors.lightTextPrimary),
    bodyLarge: bodyLarge.copyWith(color: AppColors.lightTextPrimary),
    bodyMedium: bodyMedium.copyWith(color: AppColors.lightTextSecondary),
    bodySmall: bodySmall.copyWith(color: AppColors.lightTextSecondary),
    labelLarge: labelLarge.copyWith(color: AppColors.lightTextPrimary),
    labelMedium: labelMedium.copyWith(color: AppColors.lightTextSecondary),
    labelSmall: labelSmall.copyWith(color: AppColors.lightTextTertiary),
  );
  
  /// Get text theme for dark mode
  static TextTheme darkTextTheme = TextTheme(
    displayLarge: displayLarge.copyWith(color: AppColors.darkTextPrimary),
    displayMedium: displayMedium.copyWith(color: AppColors.darkTextPrimary),
    displaySmall: displaySmall.copyWith(color: AppColors.darkTextPrimary),
    headlineLarge: headlineLarge.copyWith(color: AppColors.darkTextPrimary),
    headlineMedium: headlineMedium.copyWith(color: AppColors.darkTextPrimary),
    headlineSmall: headlineSmall.copyWith(color: AppColors.darkTextPrimary),
    titleLarge: titleLarge.copyWith(color: AppColors.darkTextPrimary),
    titleMedium: titleMedium.copyWith(color: AppColors.darkTextPrimary),
    titleSmall: titleSmall.copyWith(color: AppColors.darkTextPrimary),
    bodyLarge: bodyLarge.copyWith(color: AppColors.darkTextPrimary),
    bodyMedium: bodyMedium.copyWith(color: AppColors.darkTextSecondary),
    bodySmall: bodySmall.copyWith(color: AppColors.darkTextSecondary),
    labelLarge: labelLarge.copyWith(color: AppColors.darkTextPrimary),
    labelMedium: labelMedium.copyWith(color: AppColors.darkTextSecondary),
    labelSmall: labelSmall.copyWith(color: AppColors.darkTextTertiary),
  );
}


