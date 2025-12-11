import 'package:flutter/material.dart';

/// SportsAadhaar Color System
/// Primary: Orange (#F28D25) - Energy, action, achievement
/// Secondary: Purple (#322259) - Trust, excellence, depth
class AppColors {
  AppColors._();

  // ============== PRIMARY COLORS ==============
  static const Color primaryOrange = Color(0xFFF28D25);
  static const Color primaryOrangeLight = Color(0xFFFFAB5C);
  static const Color primaryOrangeDark = Color(0xFFD97A1F);
  
  // Orange shades for various states
  static const Color orange50 = Color(0xFFFFF4E6);
  static const Color orange100 = Color(0xFFFFE4C4);
  static const Color orange200 = Color(0xFFFFD19E);
  static const Color orange300 = Color(0xFFFFBE78);
  static const Color orange400 = Color(0xFFF9A54D);
  static const Color orange500 = Color(0xFFF28D25);  // Primary
  static const Color orange600 = Color(0xFFD97A1F);
  static const Color orange700 = Color(0xFFBF6818);
  static const Color orange800 = Color(0xFF8F4E12);
  static const Color orange900 = Color(0xFF5F340C);

  // ============== SECONDARY COLORS ==============
  static const Color secondaryPurple = Color(0xFF322259);
  static const Color secondaryPurpleLight = Color(0xFF4A3578);
  static const Color secondaryPurpleDark = Color(0xFF1E1536);
  
  // Purple shades
  static const Color purple50 = Color(0xFFF0EDF5);
  static const Color purple100 = Color(0xFFD8D0E8);
  static const Color purple200 = Color(0xFFBFB3DB);
  static const Color purple300 = Color(0xFF9680C4);
  static const Color purple400 = Color(0xFF6D50AD);
  static const Color purple500 = Color(0xFF4A3578);
  static const Color purple600 = Color(0xFF322259);  // Secondary
  static const Color purple700 = Color(0xFF271B47);
  static const Color purple800 = Color(0xFF1E1536);
  static const Color purple900 = Color(0xFF140E24);

  // ============== ACCENT COLORS ==============
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFE55C);
  static const Color goldDark = Color(0xFFCCAA00);
  
  // ============== SEMANTIC COLORS ==============
  // Success
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFF58D68D);
  static const Color successDark = Color(0xFF27AE60);
  static const Color successBg = Color(0xFFE8F8F0);
  
  // Error
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFEC7063);
  static const Color errorDark = Color(0xFFC0392B);
  static const Color errorBg = Color(0xFFFDECEA);
  
  // Warning
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFF5B041);
  static const Color warningDark = Color(0xFFD68910);
  static const Color warningBg = Color(0xFFFEF5E7);
  
  // Info
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFF5DADE2);
  static const Color infoDark = Color(0xFF2980B9);
  static const Color infoBg = Color(0xFFEBF5FB);

  // ============== NEUTRAL COLORS ==============
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ============== LIGHT THEME COLORS ==============
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // ============== DARK THEME COLORS ==============
  static const Color darkBackground = Color(0xFF0D0D14);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceVariant = Color(0xFF252540);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF8F9FA);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // ============== GAMIFICATION COLORS ==============
  // Level badges
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color goldBadge = Color(0xFFFFD700);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color diamond = Color(0xFFB9F2FF);
  
  // XP bar
  static const Color xpBarBackground = Color(0xFFE5E7EB);
  static const Color xpBarFill = Color(0xFFF28D25);
  static const Color xpBarGlow = Color(0xFFFFAB5C);
  
  // Streak
  static const Color streakFire = Color(0xFFFF6B35);
  static const Color streakFireGlow = Color(0xFFFF9A5C);
  
  // Achievement categories
  static const Color achievementPhysical = Color(0xFF2ECC71);
  static const Color achievementMental = Color(0xFF9B59B6);
  static const Color achievementDedication = Color(0xFFF28D25);
  static const Color achievementSpecial = Color(0xFFFFD700);

  // ============== TEST CATEGORY COLORS ==============
  static const Color categoryStrength = Color(0xFFE74C3C);
  static const Color categorySpeed = Color(0xFF3498DB);
  static const Color categoryEndurance = Color(0xFF2ECC71);
  static const Color categoryFlexibility = Color(0xFF9B59B6);
  static const Color categoryAgility = Color(0xFFF39C12);
  static const Color categoryMeasurement = Color(0xFF1ABC9C);

  // ============== CARD BACKGROUNDS ==============
  static const Color cardGlassLight = Color(0xB3FFFFFF);  // 70% white
  static const Color cardGlassDark = Color(0xB31A1A2E);   // 70% dark surface
  
  // ============== HELPER METHODS ==============
  
  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// Get category color by test category
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
      case 'lowerbodystrength':
      case 'upperbodystrength':
      case 'corestrength':
        return categoryStrength;
      case 'speed':
        return categorySpeed;
      case 'endurance':
        return categoryEndurance;
      case 'flexibility':
        return categoryFlexibility;
      case 'agility':
        return categoryAgility;
      case 'measurement':
        return categoryMeasurement;
      default:
        return primaryOrange;
    }
  }
  
  /// Get badge color by performance level
  static Color getBadgeColor(String level) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return bronze;
      case 'silver':
        return silver;
      case 'gold':
        return goldBadge;
      case 'platinum':
        return platinum;
      case 'diamond':
        return diamond;
      default:
        return gray400;
    }
  }
}


