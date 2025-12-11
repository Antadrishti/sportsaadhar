import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';

/// Achievement badge with unlock animation
class AchievementBadge extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final bool isUnlocked;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final VoidCallback? onTap;
  final double size;

  const AchievementBadge({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    this.isUnlocked = false,
    this.category = AchievementCategory.general,
    this.rarity = AchievementRarity.common,
    this.onTap,
    this.size = 70,
  });

  Color get _categoryColor {
    switch (category) {
      case AchievementCategory.physical:
        return AppColors.achievementPhysical;
      case AchievementCategory.mental:
        return AppColors.achievementMental;
      case AchievementCategory.dedication:
        return AppColors.achievementDedication;
      case AchievementCategory.special:
        return AppColors.achievementSpecial;
      case AchievementCategory.general:
        return AppColors.primaryOrange;
    }
  }

  Gradient get _rarityGradient {
    switch (rarity) {
      case AchievementRarity.common:
        return AppGradients.badgeBronze;
      case AchievementRarity.rare:
        return AppGradients.badgeSilver;
      case AchievementRarity.epic:
        return AppGradients.badgeGold;
      case AchievementRarity.legendary:
        return AppGradients.holographic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge icon
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isUnlocked ? _rarityGradient : null,
              color: isUnlocked ? null : AppColors.gray300,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: _categoryColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? AppColors.white : AppColors.gray200,
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(
                        icon,
                        size: size * 0.45,
                        color: _categoryColor,
                      )
                    : Icon(
                        Icons.lock,
                        size: size * 0.35,
                        color: AppColors.gray400,
                      ),
              ),
            ),
          ).animate(target: isUnlocked ? 1 : 0).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 8),
          
          // Title
          SizedBox(
            width: size + 20,
            child: Text(
              isUnlocked ? title : '???',
              style: AppTypography.labelSmall.copyWith(
                color: isUnlocked ? AppColors.lightTextPrimary : AppColors.gray400,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large achievement card for detail view
class AchievementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final DateTime? unlockedAt;
  final String? xpReward;
  final VoidCallback? onShare;

  const AchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.category = AchievementCategory.general,
    this.rarity = AchievementRarity.common,
    this.unlockedAt,
    this.xpReward,
    this.onShare,
  });

  Color get _categoryColor {
    switch (category) {
      case AchievementCategory.physical:
        return AppColors.achievementPhysical;
      case AchievementCategory.mental:
        return AppColors.achievementMental;
      case AchievementCategory.dedication:
        return AppColors.achievementDedication;
      case AchievementCategory.special:
        return AppColors.achievementSpecial;
      case AchievementCategory.general:
        return AppColors.primaryOrange;
    }
  }

  String get _rarityLabel {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? _categoryColor.withOpacity(0.3) : AppColors.gray200,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: _categoryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Badge
          AchievementBadge(
            title: '',
            icon: icon,
            isUnlocked: isUnlocked,
            category: category,
            rarity: rarity,
            size: 80,
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isUnlocked ? title : '???',
                        style: AppTypography.titleSmall.copyWith(
                          color: isUnlocked 
                              ? AppColors.lightTextPrimary 
                              : AppColors.gray400,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _rarityLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: _categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlocked ? description : 'Complete the challenge to unlock',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                if (isUnlocked && xpReward != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+$xpReward XP',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (unlockedAt != null) ...[
                        const Spacer(),
                        Text(
                          _formatDate(unlockedAt!),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Share button
          if (isUnlocked && onShare != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              color: AppColors.gray500,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Achievement popup for unlock celebration
class AchievementUnlockPopup extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final String xpReward;
  final VoidCallback onDismiss;

  const AchievementUnlockPopup({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.category = AchievementCategory.general,
    this.rarity = AchievementRarity.common,
    required this.xpReward,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 Achievement Unlocked!',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primaryOrange,
              ),
            ).animate().fadeIn().slideY(begin: -0.2),
            const SizedBox(height: 20),
            
            AchievementBadge(
              title: title,
              icon: icon,
              isUnlocked: true,
              category: category,
              rarity: rarity,
              size: 100,
            ).animate()
                .fadeIn(delay: 200.ms)
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                ),
            const SizedBox(height: 16),
            
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ).animate(delay: 400.ms).fadeIn(),
            const SizedBox(height: 8),
            
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 500.ms).fadeIn(),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.orange50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+$xpReward XP',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 600.ms).fadeIn().scale(),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                child: const Text('Awesome!'),
              ),
            ).animate(delay: 700.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

enum AchievementCategory {
  physical,
  mental,
  dedication,
  special,
  general,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}


