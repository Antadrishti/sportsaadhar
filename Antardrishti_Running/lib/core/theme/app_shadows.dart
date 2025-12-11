import 'package:flutter/material.dart';
import 'app_colors.dart';

/// SportsAadhaar Shadow & Elevation System
/// Consistent depth and elevation throughout the app
class AppShadows {
  AppShadows._();

  // ============== ELEVATION LEVELS ==============
  
  /// Level 1 - Subtle elevation (cards, inputs)
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Level 2 - Medium elevation (floating cards, dropdowns)
  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Level 3 - High elevation (modals, popovers)
  static List<BoxShadow> elevation3 = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.black.withOpacity(0.06),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
  
  /// Level 4 - Maximum elevation (dialogs, sheets)
  static List<BoxShadow> elevation4 = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: AppColors.black.withOpacity(0.08),
      blurRadius: 48,
      offset: const Offset(0, 24),
    ),
  ];

  // ============== DARK MODE SHADOWS ==============
  
  static List<BoxShadow> elevation1Dark = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevation2Dark = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.4),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> elevation3Dark = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.5),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ============== COLORED SHADOWS ==============
  
  /// Orange glow shadow - for primary buttons
  static List<BoxShadow> glowOrange = [
    BoxShadow(
      color: AppColors.primaryOrange.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.primaryOrange.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Intense orange glow - for hover/active states
  static List<BoxShadow> glowOrangeIntense = [
    BoxShadow(
      color: AppColors.primaryOrange.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.primaryOrange.withOpacity(0.3),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Purple glow shadow
  static List<BoxShadow> glowPurple = [
    BoxShadow(
      color: AppColors.secondaryPurple.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.secondaryPurple.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Gold glow - for achievements
  static List<BoxShadow> glowGold = [
    BoxShadow(
      color: AppColors.gold.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.gold.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Success glow - for completed states
  static List<BoxShadow> glowSuccess = [
    BoxShadow(
      color: AppColors.success.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Error glow
  static List<BoxShadow> glowError = [
    BoxShadow(
      color: AppColors.error.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============== SPECIAL SHADOWS ==============
  
  /// Card shadow with slight colored tint
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.secondaryPurple.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.black.withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  /// Button shadow
  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Pressed button shadow (inset effect simulated)
  static List<BoxShadow> buttonPressed = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.12),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];
  
  /// Inner shadow for inputs
  static List<BoxShadow> innerShadow = [
    BoxShadow(
      color: AppColors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
  
  /// Sports card 3D effect
  static List<BoxShadow> sportsCard = [
    BoxShadow(
      color: AppColors.secondaryPurple.withOpacity(0.4),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: AppColors.primaryOrange.withOpacity(0.2),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];
  
  /// Text shadow for readability on images
  static List<Shadow> textShadow = [
    Shadow(
      color: AppColors.black.withOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Strong text shadow
  static List<Shadow> textShadowStrong = [
    Shadow(
      color: AppColors.black.withOpacity(0.5),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ============== HELPER METHODS ==============
  
  /// Get elevation shadows by level (1-4)
  static List<BoxShadow> getElevation(int level, {bool isDark = false}) {
    if (isDark) {
      switch (level) {
        case 1:
          return elevation1Dark;
        case 2:
          return elevation2Dark;
        case 3:
          return elevation3Dark;
        default:
          return elevation1Dark;
      }
    }
    
    switch (level) {
      case 1:
        return elevation1;
      case 2:
        return elevation2;
      case 3:
        return elevation3;
      case 4:
        return elevation4;
      default:
        return elevation1;
    }
  }
  
  /// Get glow shadow by color name
  static List<BoxShadow> getGlow(String color) {
    switch (color.toLowerCase()) {
      case 'orange':
        return glowOrange;
      case 'purple':
        return glowPurple;
      case 'gold':
        return glowGold;
      case 'success':
      case 'green':
        return glowSuccess;
      case 'error':
      case 'red':
        return glowError;
      default:
        return glowOrange;
    }
  }
}


