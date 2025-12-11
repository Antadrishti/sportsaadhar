import 'package:flutter/material.dart';
import 'app_colors.dart';

/// SportsAadhaar Gradient Presets
/// Consistent gradient styles used throughout the app
class AppGradients {
  AppGradients._();

  // ============== PRIMARY GRADIENTS ==============
  
  /// Main orange gradient - for primary buttons and highlights
  static const LinearGradient primaryOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryOrangeLight,
      AppColors.primaryOrange,
      AppColors.primaryOrangeDark,
    ],
  );
  
  /// Subtle orange gradient - for backgrounds
  static const LinearGradient primaryOrangeSubtle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.orange50,
      Color(0xFFFFFFFF),
    ],
  );
  
  /// Main purple gradient - for headers and important sections
  static const LinearGradient primaryPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryPurpleLight,
      AppColors.secondaryPurple,
      AppColors.secondaryPurpleDark,
    ],
  );
  
  /// Subtle purple gradient
  static const LinearGradient primaryPurpleSubtle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.purple50,
      Color(0xFFFFFFFF),
    ],
  );

  // ============== BRAND GRADIENTS ==============
  
  /// Orange to purple - signature brand gradient
  static const LinearGradient brandOrangePurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryOrange,
      AppColors.secondaryPurple,
    ],
  );
  
  /// Purple to orange - inverse brand gradient
  static const LinearGradient brandPurpleOrange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryPurple,
      AppColors.primaryOrange,
    ],
  );
  
  /// Diagonal brand gradient
  static const LinearGradient brandDiagonal = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      AppColors.primaryOrangeLight,
      AppColors.primaryOrange,
      AppColors.secondaryPurpleLight,
      AppColors.secondaryPurple,
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  // ============== BACKGROUND GRADIENTS ==============
  
  /// Light mode background
  static const LinearGradient backgroundLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFBF7),  // Warm white
      AppColors.lightBackground,
    ],
  );
  
  /// Dark mode background
  static const LinearGradient backgroundDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF151520),
      AppColors.darkBackground,
    ],
  );
  
  /// Welcome/Auth screen background
  static const LinearGradient authBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8F0),
      Color(0xFFF5F0FF),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  /// Journey dashboard header
  static const LinearGradient dashboardHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryPurple,
      AppColors.secondaryPurpleLight,
    ],
  );

  // ============== CARD GRADIENTS ==============
  
  /// Glass card overlay (light)
  static LinearGradient glassLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.9),
      Colors.white.withOpacity(0.7),
    ],
  );
  
  /// Glass card overlay (dark)
  static LinearGradient glassDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.darkSurface.withOpacity(0.9),
      AppColors.darkSurface.withOpacity(0.7),
    ],
  );
  
  /// Achievement card background
  static const LinearGradient achievementCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gold,
      AppColors.goldDark,
    ],
  );

  // ============== GAMIFICATION GRADIENTS ==============
  
  /// XP bar gradient
  static const LinearGradient xpBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.primaryOrangeDark,
      AppColors.primaryOrange,
      AppColors.primaryOrangeLight,
    ],
  );
  
  /// Level up celebration
  static const LinearGradient levelUp = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.gold,
      AppColors.primaryOrange,
      AppColors.secondaryPurple,
    ],
  );
  
  /// Streak fire gradient
  static const LinearGradient streakFire = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFFFF4500),  // Red-orange
      AppColors.streakFire,
      AppColors.gold,
    ],
  );
  
  /// Bronze badge
  static const LinearGradient badgeBronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4A574),
      AppColors.bronze,
      Color(0xFF8B5A2B),
    ],
  );
  
  /// Silver badge
  static const LinearGradient badgeSilver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8E8E8),
      AppColors.silver,
      Color(0xFF808080),
    ],
  );
  
  /// Gold badge
  static const LinearGradient badgeGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE55C),
      AppColors.goldBadge,
      Color(0xFFCCAA00),
    ],
  );

  // ============== TEST CATEGORY GRADIENTS ==============
  
  static const LinearGradient categoryStrength = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      AppColors.categoryStrength,
    ],
  );
  
  static const LinearGradient categorySpeed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF74B9FF),
      AppColors.categorySpeed,
    ],
  );
  
  static const LinearGradient categoryEndurance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF55EFC4),
      AppColors.categoryEndurance,
    ],
  );
  
  static const LinearGradient categoryFlexibility = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA29BFE),
      AppColors.categoryFlexibility,
    ],
  );

  // ============== PSYCHOMETRIC GRADIENTS ==============
  
  /// Mental/Psychometric purple gradient
  static const LinearGradient mentalPurple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.achievementMental,
      AppColors.secondaryPurple,
    ],
  );
  
  // ============== MEDAL GRADIENTS ==============
  
  /// Gold medal gradient
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE55C),
      AppColors.gold,
      Color(0xFFD4AF37),
    ],
  );
  
  /// Silver medal gradient
  static const LinearGradient silver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8E8E8),
      AppColors.silver,
      Color(0xFFA8A8A8),
    ],
  );
  
  /// Bronze medal gradient
  static const LinearGradient bronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4A574),
      AppColors.bronze,
      Color(0xFF8B5A2B),
    ],
  );

  // ============== SPORTS CARD GRADIENTS ==============
  
  /// Premium card gradient
  static const LinearGradient cardPremium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryPurple,
      Color(0xFF4A3578),
      AppColors.primaryOrangeDark,
    ],
  );
  
  /// Holographic shimmer effect
  static const LinearGradient holographic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFFE66D),
      Color(0xFF4ECDC4),
      Color(0xFF45B7D1),
      Color(0xFF96CEB4),
      Color(0xFFFF6B6B),
    ],
    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
  );
  
  /// Card background
  static const LinearGradient sportsCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.secondaryPurple,
      Color(0xFF4A3578),
      AppColors.secondaryPurpleDark,
    ],
  );

  // ============== SHIMMER/LOADING GRADIENTS ==============
  
  static LinearGradient shimmerLight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.gray200,
      AppColors.gray100,
      AppColors.gray200,
    ],
    stops: const [0.0, 0.5, 1.0],
  );
  
  static LinearGradient shimmerDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.gray800,
      AppColors.gray700,
      AppColors.gray800,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // ============== RADIAL GRADIENTS ==============
  
  /// Glow effect behind elements
  static RadialGradient glowOrange = RadialGradient(
    colors: [
      AppColors.primaryOrange.withOpacity(0.4),
      AppColors.primaryOrange.withOpacity(0.0),
    ],
  );
  
  static RadialGradient glowPurple = RadialGradient(
    colors: [
      AppColors.secondaryPurple.withOpacity(0.4),
      AppColors.secondaryPurple.withOpacity(0.0),
    ],
  );
  
  static RadialGradient glowGold = RadialGradient(
    colors: [
      AppColors.gold.withOpacity(0.4),
      AppColors.gold.withOpacity(0.0),
    ],
  );

  // ============== HELPER METHODS ==============
  
  /// Get badge gradient by level
  static LinearGradient getBadgeGradient(String level) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return badgeBronze;
      case 'silver':
        return badgeSilver;
      case 'gold':
        return badgeGold;
      default:
        return badgeBronze;
    }
  }
  
  /// Get category gradient
  static LinearGradient getCategoryGradient(String category) {
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
      default:
        return primaryOrange;
    }
  }
}


