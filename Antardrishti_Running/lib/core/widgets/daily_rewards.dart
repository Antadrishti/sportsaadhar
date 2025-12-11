import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'confetti_overlay.dart';

/// Daily rewards calendar showing 7-day login streak
class DailyRewardsCalendar extends StatelessWidget {
  final int currentDay; // 1-7
  final bool canClaimToday;
  final List<bool> claimedDays; // 7 bools
  final VoidCallback onClaimToday;

  const DailyRewardsCalendar({
    super.key,
    required this.currentDay,
    required this.canClaimToday,
    required this.claimedDays,
    required this.onClaimToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPurple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: AppGradients.brandPurpleOrange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '🎁',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Rewards',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Day $currentDay of 7',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (canClaimToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Claim!',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 500.ms),
              ],
            ),
          ),

          // Days grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final dayNumber = index + 1;
                final isClaimed = claimedDays.length > index && claimedDays[index];
                final isToday = dayNumber == currentDay;
                final isFuture = dayNumber > currentDay;

                return _DayRewardItem(
                  day: dayNumber,
                  reward: _getRewardForDay(dayNumber),
                  isClaimed: isClaimed,
                  isToday: isToday,
                  isFuture: isFuture,
                  canClaim: isToday && canClaimToday,
                  onClaim: isToday && canClaimToday ? onClaimToday : null,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  DayReward _getRewardForDay(int day) {
    switch (day) {
      case 1:
        return const DayReward(xp: 10, coins: 5, icon: '⭐');
      case 2:
        return const DayReward(xp: 20, coins: 10, icon: '💫');
      case 3:
        return const DayReward(xp: 30, coins: 15, icon: '🎁', hasChest: true);
      case 4:
        return const DayReward(xp: 40, coins: 20, icon: '✨');
      case 5:
        return const DayReward(xp: 50, coins: 25, icon: '🎁', hasChest: true);
      case 6:
        return const DayReward(xp: 75, coins: 40, icon: '🌟');
      case 7:
        return const DayReward(xp: 100, coins: 50, icon: '👑', hasChest: true, isGold: true);
      default:
        return const DayReward(xp: 10, coins: 5, icon: '⭐');
    }
  }
}

class _DayRewardItem extends StatelessWidget {
  final int day;
  final DayReward reward;
  final bool isClaimed;
  final bool isToday;
  final bool isFuture;
  final bool canClaim;
  final VoidCallback? onClaim;

  const _DayRewardItem({
    required this.day,
    required this.reward,
    required this.isClaimed,
    required this.isToday,
    required this.isFuture,
    required this.canClaim,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canClaim
          ? () {
              HapticFeedback.mediumImpact();
              onClaim?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 44,
        child: Column(
          children: [
            // Day number
            Text(
              'D$day',
              style: AppTypography.labelSmall.copyWith(
                color: isToday
                    ? AppColors.primaryOrange
                    : isFuture
                        ? AppColors.gray400
                        : AppColors.success,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            
            // Reward icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isClaimed
                    ? AppColors.success
                    : isToday
                        ? reward.isGold
                            ? AppColors.gold
                            : AppColors.primaryOrange
                        : isFuture
                            ? AppColors.gray200
                            : AppColors.gray300,
                border: isToday && canClaim
                    ? Border.all(color: AppColors.primaryOrange, width: 2)
                    : null,
                boxShadow: isToday && canClaim
                    ? [
                        BoxShadow(
                          color: AppColors.primaryOrange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isClaimed
                    ? const Icon(Icons.check, color: AppColors.white, size: 20)
                    : Text(
                        reward.icon,
                        style: TextStyle(
                          fontSize: isFuture ? 14 : 18,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Reward value
            Text(
              '+${reward.xp}',
              style: AppTypography.labelSmall.copyWith(
                color: isFuture ? AppColors.gray400 : AppColors.lightTextSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DayReward {
  final int xp;
  final int coins;
  final String icon;
  final bool hasChest;
  final bool isGold;

  const DayReward({
    required this.xp,
    required this.coins,
    required this.icon,
    this.hasChest = false,
    this.isGold = false,
  });
}

/// Daily reward claim popup
class DailyRewardClaimPopup extends StatefulWidget {
  final int day;
  final DayReward reward;
  final VoidCallback onClaimed;

  const DailyRewardClaimPopup({
    super.key,
    required this.day,
    required this.reward,
    required this.onClaimed,
  });

  static Future<void> show(
    BuildContext context, {
    required int day,
    required DayReward reward,
  }) async {
    HapticFeedback.heavyImpact();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailyRewardClaimPopup(
        day: day,
        reward: reward,
        onClaimed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<DailyRewardClaimPopup> createState() => _DailyRewardClaimPopupState();
}

class _DailyRewardClaimPopupState extends State<DailyRewardClaimPopup> {
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showConfetti = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: _showConfetti,
      type: widget.reward.isGold ? ConfettiType.gold : ConfettiType.celebration,
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
                'Day ${widget.day} Reward!',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.secondaryPurple,
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 24),

              // Reward box animation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: widget.reward.isGold
                      ? AppGradients.badgeGold
                      : AppGradients.orangeLight,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.reward.isGold ? AppColors.gold : AppColors.primaryOrange)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.reward.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(curve: Curves.elasticOut, duration: 800.ms),

              const SizedBox(height: 24),

              // Rewards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RewardChip(
                    icon: '⚡',
                    value: '+${widget.reward.xp} XP',
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 12),
                  _RewardChip(
                    icon: '🪙',
                    value: '+${widget.reward.coins}',
                    color: AppColors.gold,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              if (widget.reward.hasChest) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.reward.isGold
                        ? AppColors.gold.withValues(alpha: 0.1)
                        : AppColors.purple50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.reward.isGold ? '🎁' : '📦',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.reward.isGold ? 'Gold Chest!' : 'Bonus Chest!',
                        style: AppTypography.labelMedium.copyWith(
                          color: widget.reward.isGold
                              ? AppColors.goldDark
                              : AppColors.secondaryPurple,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).scale(),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onClaimed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.reward.isGold
                        ? AppColors.gold
                        : AppColors.primaryOrange,
                  ),
                  child: const Text('Collect! 🎉'),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String icon;
  final String value;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

