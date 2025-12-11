import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'confetti_overlay.dart';

/// Full-screen level up celebration
class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final String newTitle;
  final String badge;
  final int xpEarned;
  final VoidCallback onDismiss;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    required this.newTitle,
    required this.badge,
    required this.xpEarned,
    required this.onDismiss,
  });

  /// Show as a dialog
  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String newTitle,
    required String badge,
    required int xpEarned,
  }) {
    HapticFeedback.heavyImpact();
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => LevelUpCelebration(
        newLevel: newLevel,
        newTitle: newTitle,
        badge: badge,
        xpEarned: xpEarned,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  bool _showConfetti = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _showConfetti = true);
      HapticFeedback.mediumImpact();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _showContent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: _showConfetti,
      type: ConfettiType.gold,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _showContent
            ? _buildContent()
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppGradients.brandPurpleOrange,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level up text
          Text(
            '🎉 LEVEL UP! 🎉',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),

          const SizedBox(height: 32),

          // Level badge
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.badgeGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.badge,
                    style: const TextStyle(fontSize: 40),
                  ),
                  Text(
                    'Lv.${widget.newLevel}',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 800.ms,
              ),

          const SizedBox(height: 24),

          // New title
          Text(
            widget.newTitle,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 0.3),

          const SizedBox(height: 8),

          Text(
            'New Title Unlocked!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.8),
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 24),

          // Rewards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: AppColors.gold, size: 24),
                const SizedBox(width: 8),
                Text(
                  '+${widget.xpEarned} XP Bonus',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 700.ms).scale(),

          const SizedBox(height: 32),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.secondaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Awesome! 🚀',
                style: AppTypography.button.copyWith(
                  color: AppColors.secondaryPurple,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }
}

/// Reward popup for XP, coins, etc.
class RewardPopup extends StatelessWidget {
  final String title;
  final List<RewardItem> rewards;
  final VoidCallback onClaim;
  final bool showConfetti;

  const RewardPopup({
    super.key,
    required this.title,
    required this.rewards,
    required this.onClaim,
    this.showConfetti = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<RewardItem> rewards,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RewardPopup(
        title: title,
        rewards: rewards,
        onClaim: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: showConfetti,
      type: ConfettiType.celebration,
      child: Dialog(
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
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondaryPurple,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 24),

              // Rewards list
              ...rewards.asMap().entries.map((entry) {
                final index = entry.key;
                final reward = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _RewardRow(reward: reward),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 200 + index * 100))
                    .slideX(begin: -0.2);
              }),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClaim,
                  child: const Text('Claim!'),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final RewardItem reward;

  const _RewardRow({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: reward.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reward.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reward.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reward.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  reward.value,
                  style: AppTypography.titleSmall.copyWith(
                    color: reward.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RewardItem {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const RewardItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color = AppColors.primaryOrange,
  });
}

/// Achievement unlock popup
class AchievementUnlockCelebration extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final VoidCallback onDismiss;

  const AchievementUnlockCelebration({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required String icon,
    required int xpReward,
  }) {
    HapticFeedback.mediumImpact();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockCelebration(
        title: title,
        description: description,
        icon: icon,
        xpReward: xpReward,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: true,
      type: ConfettiType.celebration,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppGradients.badgeGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🏆 Achievement Unlocked!',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ).animate().fadeIn().scale(),

              const SizedBox(height: 24),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.badgeGold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 48)),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(
                    begin: const Offset(0, 0),
                    curve: Curves.elasticOut,
                    duration: 800.ms,
                  ),

              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 8),

              Text(
                description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 16),

              // XP Reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.orange50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: AppColors.primaryOrange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '+$xpReward XP',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).scale(),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Share functionality
                        onDismiss();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, size: 18),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      child: const Text('Awesome!'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }
}

