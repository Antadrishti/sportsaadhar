import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Animated coin display widget
class CoinDisplay extends StatelessWidget {
  final int coins;
  final bool compact;
  final VoidCallback? onTap;

  const CoinDisplay({
    super.key,
    required this.coins,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                _formatNumber(coins),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🪙', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Coins',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.goldDark.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  _formatNumber(coins),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.add_circle,
              color: AppColors.gold,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }
}

/// Floating coin animation when earning coins
class FloatingCoinAnimation extends StatelessWidget {
  final int amount;
  final VoidCallback? onComplete;

  const FloatingCoinAnimation({
    super.key,
    required this.amount,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(
            '+$amount',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.5, end: 0, duration: 300.ms)
        .then()
        .fadeOut(delay: 800.ms, duration: 300.ms);
  }
}

/// Floating XP animation when earning XP
class FloatingXPAnimation extends StatelessWidget {
  final int amount;
  final double? multiplier;
  final VoidCallback? onComplete;

  const FloatingXPAnimation({
    super.key,
    required this.amount,
    this.multiplier,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryOrange, AppColors.primaryOrangeDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(
            '+$amount XP',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (multiplier != null && multiplier! > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${multiplier}x',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(onComplete: (_) => onComplete?.call())
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.5, end: 0, duration: 300.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 300.ms)
        .then()
        .fadeOut(delay: 800.ms, duration: 300.ms);
  }
}

/// Multiplier badge display
class MultiplierBadge extends StatelessWidget {
  final double multiplier;
  final String? reason;

  const MultiplierBadge({
    super.key,
    required this.multiplier,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    if (multiplier <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A5A)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '${multiplier}x XP',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reason != null) ...[
            const SizedBox(width: 4),
            Text(
              '• $reason',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1000.ms);
  }
}

/// Combo counter display
class ComboCounter extends StatelessWidget {
  final int combo;
  final int bonusXP;

  const ComboCounter({
    super.key,
    required this.combo,
    required this.bonusXP,
  });

  @override
  Widget build(BuildContext context) {
    if (combo < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange,
            combo >= 5 ? const Color(0xFFFF4444) : AppColors.primaryOrangeDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: TextStyle(fontSize: combo >= 5 ? 24 : 20),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COMBO x$combo',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '+$bonusXP bonus XP',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: Offset(1 + (combo * 0.01), 1 + (combo * 0.01)),
          duration: const Duration(milliseconds: 500),
        );
  }
}

