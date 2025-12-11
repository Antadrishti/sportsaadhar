import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';

/// Weekly streak calendar showing login/activity streak
class StreakCalendar extends StatelessWidget {
  final int currentStreak;
  final List<bool> weekDays; // 7 bools for Mon-Sun, true = active
  final bool showFireAnimation;

  const StreakCalendar({
    super.key,
    required this.currentStreak,
    required this.weekDays,
    this.showFireAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with streak count
          Row(
            children: [
              if (showFireAnimation && currentStreak > 0)
                _FireIcon(streak: currentStreak)
              else
                Icon(
                  Icons.local_fire_department,
                  color: currentStreak > 0 
                      ? AppColors.streakFire 
                      : AppColors.gray400,
                  size: 24,
                ),
              const SizedBox(width: 8),
              Text(
                '$currentStreak Day Streak',
                style: AppTypography.titleSmall.copyWith(
                  color: currentStreak > 0 
                      ? AppColors.streakFire 
                      : AppColors.gray500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (currentStreak >= 7)
                _StreakBadge(streak: currentStreak),
            ],
          ),
          const SizedBox(height: 16),
          
          // Week days row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isActive = index < weekDays.length && weekDays[index];
              final isToday = index == DateTime.now().weekday - 1;
              
              return _DayCircle(
                day: days[index],
                isActive: isActive,
                isToday: isToday,
                index: index,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FireIcon extends StatelessWidget {
  final int streak;

  const _FireIcon({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.streakFire.withOpacity(0.3),
                AppColors.streakFire.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Fire icon
        Icon(
          Icons.local_fire_department,
          color: AppColors.streakFire,
          size: 24,
        )
            .animate(onPlay: (controller) => controller.repeat())
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 600.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1, 1),
              duration: 600.ms,
            ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  String get _badgeText {
    if (streak >= 30) return '🔥 On Fire!';
    if (streak >= 14) return '⚡ Unstoppable';
    if (streak >= 7) return '💪 Strong';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppGradients.streakFire,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _badgeText,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.8, 0.8),
      curve: Curves.elasticOut,
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String day;
  final bool isActive;
  final bool isToday;
  final int index;

  const _DayCircle({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: AppTypography.labelSmall.copyWith(
            color: isToday ? AppColors.primaryOrange : AppColors.gray500,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? AppColors.success 
                : isToday 
                    ? AppColors.orange50
                    : AppColors.gray100,
            border: isToday && !isActive
                ? Border.all(color: AppColors.primaryOrange, width: 2)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isActive
                ? const Icon(
                    Icons.check,
                    color: AppColors.white,
                    size: 20,
                  )
                : isToday
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryOrange,
                        ),
                      )
                    : null,
          ),
        )
            .animate(delay: Duration(milliseconds: 50 * index))
            .fadeIn()
            .scale(begin: const Offset(0.5, 0.5)),
      ],
    );
  }
}

/// Compact streak indicator for headers
class StreakIndicatorCompact extends StatelessWidget {
  final int streak;

  const StreakIndicatorCompact({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: streak > 0 
            ? AppColors.streakFire.withOpacity(0.1) 
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: streak > 0 
              ? AppColors.streakFire.withOpacity(0.3) 
              : AppColors.gray200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 16,
            color: streak > 0 ? AppColors.streakFire : AppColors.gray400,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: AppTypography.labelMedium.copyWith(
              color: streak > 0 ? AppColors.streakFire : AppColors.gray500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


