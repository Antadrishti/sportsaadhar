import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';
import 'confetti_overlay.dart';

/// XP Gain Animation Widget
/// Shows animated XP gain with rating badge and bonuses
class XPGainAnimation extends StatefulWidget {
  final int totalXP;
  final int baseXP;
  final int? ratingBonusXP;
  final int? improvementBonusXP;
  final String? rating; // bronze, silver, gold, platinum
  final bool isPersonalBest;
  final VoidCallback? onComplete;

  const XPGainAnimation({
    super.key,
    required this.totalXP,
    required this.baseXP,
    this.ratingBonusXP,
    this.improvementBonusXP,
    this.rating,
    this.isPersonalBest = false,
    this.onComplete,
  });

  @override
  State<XPGainAnimation> createState() => _XPGainAnimationState();
}

class _XPGainAnimationState extends State<XPGainAnimation> {
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    
    // Show confetti for gold/platinum ratings
    if (widget.rating == 'gold' || widget.rating == 'platinum') {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showConfetti = true);
      });
    }
    
    // Auto-dismiss after animation
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  Color get _ratingColor {
    switch (widget.rating) {
      case 'platinum':
        return AppColors.achievementSpecial;
      case 'gold':
        return AppColors.gold;
      case 'silver':
        return AppColors.silver;
      case 'bronze':
        return AppColors.bronze;
      default:
        return AppColors.primaryOrange;
    }
  }

  String get _ratingEmoji {
    switch (widget.rating) {
      case 'platinum':
        return '💎';
      case 'gold':
        return '🥇';
      case 'silver':
        return '🥈';
      case 'bronze':
        return '🥉';
      default:
        return '⭐';
    }
  }

  String get _ratingLabel {
    switch (widget.rating) {
      case 'platinum':
        return 'PLATINUM';
      case 'gold':
        return 'GOLD';
      case 'silver':
        return 'SILVER';
      case 'bronze':
        return 'BRONZE';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _ratingColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rating badge
                if (widget.rating != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _ratingColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _ratingColor, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _ratingEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _ratingLabel,
                          style: AppTypography.labelLarge.copyWith(
                            color: _ratingColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 100.ms)
                      .scale(curve: Curves.elasticOut),
                  const SizedBox(height: 20),
                ],

                // Total XP gain
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '⚡',
                      style: TextStyle(fontSize: 40),
                    ).animate(onPlay: (controller) => controller.repeat())
                        .shake(duration: 500.ms, hz: 2, rotation: 0.05),
                    const SizedBox(width: 12),
                    Text(
                      '+${widget.totalXP}',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(delay: 200.ms).scale(
                        begin: const Offset(0.5, 0.5),
                        curve: Curves.elasticOut,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'XP',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primaryOrange,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),

                const SizedBox(height: 16),

                // XP breakdown
                Column(
                  children: [
                    _XPBreakdownRow(
                      label: 'Base XP',
                      value: widget.baseXP,
                      delay: 400,
                    ),
                    if (widget.ratingBonusXP != null && widget.ratingBonusXP! > 0)
                      _XPBreakdownRow(
                        label: '${_ratingLabel} Bonus',
                        value: widget.ratingBonusXP!,
                        color: _ratingColor,
                        delay: 500,
                      ),
                    if (widget.isPersonalBest && widget.improvementBonusXP != null && widget.improvementBonusXP! > 0)
                      _XPBreakdownRow(
                        label: '🎯 Personal Best!',
                        value: widget.improvementBonusXP!,
                        color: AppColors.success,
                        delay: 600,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Continue button (optional)
                TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    'Continue',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),

        // Confetti overlay for gold/platinum
        if (_showConfetti)
          ConfettiOverlay(
            isActive: _showConfetti,
            type: widget.rating == 'platinum' 
                ? ConfettiType.epic 
                : ConfettiType.gold,
            onComplete: () {
              if (mounted) setState(() => _showConfetti = false);
            },
            child: const SizedBox.shrink(),
          ),
      ],
    );
  }
}

class _XPBreakdownRow extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;
  final int delay;

  const _XPBreakdownRow({
    required this.label,
    required this.value,
    this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: color ?? AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$value XP',
            style: AppTypography.labelMedium.copyWith(
              color: color ?? AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideX(begin: 0.1);
  }
}

/// Compact XP gain toast for quick display
class XPGainToast extends StatelessWidget {
  final int xp;
  final String? label;

  const XPGainToast({
    super.key,
    required this.xp,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppGradients.xpBar,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt,
            color: AppColors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '+$xp XP',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Text(
              '• $label',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  /// Show as overlay toast
  static void show(BuildContext context, {required int xp, String? label}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 80,
        left: 0,
        right: 0,
        child: Center(
          child: XPGainToast(xp: xp, label: label),
        ),
      ),
    );
    
    overlay.insert(entry);
    
    // Auto-remove after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }
}


