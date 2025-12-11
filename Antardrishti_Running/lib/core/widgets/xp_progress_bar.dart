import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_typography.dart';

/// Animated XP Progress Bar with level indicator
/// Shows current XP, progress to next level, and level badge
class XPProgressBar extends StatefulWidget {
  final int currentXP;
  final int currentLevel;
  final int xpForCurrentLevel;
  final int xpForNextLevel;
  final String levelTitle;
  final bool showLevelBadge;
  final bool animate;
  final double height;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.currentLevel,
    required this.xpForCurrentLevel,
    required this.xpForNextLevel,
    this.levelTitle = '',
    this.showLevelBadge = true,
    this.animate = true,
    this.height = 10,
  });

  @override
  State<XPProgressBar> createState() => _XPProgressBarState();
}

class _XPProgressBarState extends State<XPProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    final progress = _calculateProgress();
    _progressAnimation = Tween<double>(
      begin: 0,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(XPProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXP != widget.currentXP) {
      final newProgress = _calculateProgress();
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateProgress() {
    final xpInCurrentLevel = widget.currentXP - widget.xpForCurrentLevel;
    final xpNeededForLevel = widget.xpForNextLevel - widget.xpForCurrentLevel;
    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final xpInCurrentLevel = widget.currentXP - widget.xpForCurrentLevel;
    final xpNeededForLevel = widget.xpForNextLevel - widget.xpForCurrentLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level info row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (widget.showLevelBadge) ...[
                  _LevelBadge(level: widget.currentLevel),
                  const SizedBox(width: 8),
                ],
                if (widget.levelTitle.isNotEmpty)
                  Text(
                    widget.levelTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.secondaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            Text(
              '$xpInCurrentLevel / $xpNeededForLevel XP',
              style: AppTypography.xpNumber.copyWith(
                color: AppColors.primaryOrange,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Background
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: AppColors.xpBarBackground,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
                // Progress fill
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      gradient: AppGradients.xpBar,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryOrange.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Glow effect at the end
                if (_progressAnimation.value > 0.05)
                  Positioned(
                    left: (_progressAnimation.value * 
                        (MediaQuery.of(context).size.width - 48)) - 4,
                    child: Container(
                      width: 8,
                      height: widget.height,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrangeLight.withOpacity(0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  Color get _badgeColor {
    if (level >= 9) return AppColors.goldBadge;
    if (level >= 7) return AppColors.goldBadge;
    if (level >= 4) return AppColors.silver;
    return AppColors.bronze;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _badgeColor.withOpacity(0.2),
            _badgeColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _badgeColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 14,
            color: _badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Lv.$level',
            style: AppTypography.labelMedium.copyWith(
              color: _badgeColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ).animate().scale(
      duration: 400.ms,
      curve: Curves.elasticOut,
    );
  }
}

/// Compact XP bar for headers
class XPProgressBarCompact extends StatelessWidget {
  final int currentXP;
  final int xpForNextLevel;
  final int xpForCurrentLevel;

  const XPProgressBarCompact({
    super.key,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.xpForCurrentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((currentXP - xpForCurrentLevel) / 
        (xpForNextLevel - xpForCurrentLevel)).clamp(0.0, 1.0);

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.xpBarBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.xpBar,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}


