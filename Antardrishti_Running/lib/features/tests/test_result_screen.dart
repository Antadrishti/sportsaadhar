import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_button.dart';
import '../../core/widgets/confetti_overlay.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/progress_ring.dart';

/// Test Result Screen - Shows celebration and score after test
class TestResultScreen extends StatefulWidget {
  final String testName;
  final int score;
  final int maxScore;
  final BadgeLevel badgeLevel;
  final int xpEarned;
  final int percentile;
  final String? newBadge;
  final String? previousBest;
  final VoidCallback? onRetry;
  final VoidCallback? onShare;
  final VoidCallback onNext;

  const TestResultScreen({
    super.key,
    required this.testName,
    required this.score,
    this.maxScore = 100,
    required this.badgeLevel,
    required this.xpEarned,
    required this.percentile,
    this.newBadge,
    this.previousBest,
    this.onRetry,
    this.onShare,
    required this.onNext,
  });

  @override
  State<TestResultScreen> createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scoreAnimation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _scoreController.forward();
      if (widget.badgeLevel != BadgeLevel.none) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() => _showConfetti = true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildScoreCard(),
                        const SizedBox(height: 20),
                        _buildBadgeSection(),
                        const SizedBox(height: 20),
                        _buildStatsSection(),
                        if (widget.newBadge != null) ...[
                          const SizedBox(height: 20),
                          _buildNewBadgeCard(),
                        ],
                        const SizedBox(height: 30),
                        _buildActions(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti Overlay
          if (_showConfetti)
            ConfettiOverlay(
              isActive: _showConfetti,
              onComplete: () {
                if (mounted) {
                  setState(() => _showConfetti = false);
                }
              },
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      decoration: BoxDecoration(
        gradient: _getBadgeGradient(),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // Status Bar
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: AppColors.white.withValues(alpha: 0.8),
              ),
              const Spacer(),
              // XP Earned Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 18,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.xpEarned} XP',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 2000.ms).scale(),
            ],
          ),

          const SizedBox(height: 20),

          // Success Message
          Text(
            _getSuccessMessage(),
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),

          Text(
            widget.testName,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return SolidGlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Animated Score Ring
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return ScoreRing(
                score: _scoreAnimation.value.toInt(),
                label: 'Score',
                size: 160,
                color: _getBadgeColor(),
              );
            },
          ),

          const SizedBox(height: 20),

          // Percentile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _getBadgeColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: _getBadgeColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Better than ${widget.percentile}% of athletes',
                  style: AppTypography.labelLarge.copyWith(
                    color: _getBadgeColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 2200.ms).slideY(begin: 0.2),

          // Previous Best
          if (widget.previousBest != null) ...[
            const SizedBox(height: 12),
            Text(
              'Previous Best: ${widget.previousBest}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ).animate().fadeIn(delay: 2400.ms),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildBadgeSection() {
    return SolidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Badge Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: _getBadgeGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getBadgeColor().withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getBadgeEmoji(),
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ).animate(delay: 1800.ms).scale(curve: Curves.elasticOut),

          const SizedBox(width: 16),

          // Badge Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getBadgeName(),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getBadgeDescription(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ).animate(delay: 1900.ms).fadeIn().slideX(begin: 0.1),

          // Share Button
          IconButton(
            onPressed: widget.onShare,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share,
                size: 20,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1700.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.timer,
            value: '4.2s',
            label: 'Time',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            icon: Icons.leaderboard,
            value: '#127',
            label: 'Rank',
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            icon: Icons.local_fire_department,
            value: '5',
            label: 'Streak',
            color: AppColors.error,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 2000.ms).slideY(begin: 0.1);
  }

  Widget _buildNewBadgeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.2),
            AppColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('🏅', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Achievement Unlocked!',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.newBadge!,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.gold,
          ),
        ],
      ),
    ).animate(delay: 2500.ms).fadeIn().shake(hz: 2, rotation: 0.02);
  }

  Widget _buildActions() {
    return Column(
      children: [
        AnimatedPrimaryButton(
          label: 'Continue to Next Test',
          icon: Icons.arrow_forward,
          iconAtEnd: true,
          onPressed: widget.onNext,
          useGradient: true,
        ).animate().fadeIn(delay: 2600.ms),

        const SizedBox(height: 12),

        Row(
          children: [
            if (widget.onRetry != null)
              Expanded(
                child: AnimatedSecondaryButton(
                  label: 'Retry',
                  icon: Icons.replay,
                  onPressed: widget.onRetry!,
                ),
              ),
            if (widget.onRetry != null) const SizedBox(width: 12),
            Expanded(
              child: AnimatedSecondaryButton(
                label: 'Share Result',
                icon: Icons.share,
                onPressed: widget.onShare ?? () {},
              ),
            ),
          ],
        ).animate().fadeIn(delay: 2700.ms),
      ],
    );
  }

  String _getSuccessMessage() {
    switch (widget.badgeLevel) {
      case BadgeLevel.gold:
        return '🎉 Outstanding Performance!';
      case BadgeLevel.silver:
        return '⭐ Great Job!';
      case BadgeLevel.bronze:
        return '👍 Good Effort!';
      case BadgeLevel.none:
        return 'Test Complete';
    }
  }

  LinearGradient _getBadgeGradient() {
    switch (widget.badgeLevel) {
      case BadgeLevel.gold:
        return AppGradients.gold;
      case BadgeLevel.silver:
        return AppGradients.silver;
      case BadgeLevel.bronze:
        return AppGradients.bronze;
      case BadgeLevel.none:
        return AppGradients.primaryOrange;
    }
  }

  Color _getBadgeColor() {
    switch (widget.badgeLevel) {
      case BadgeLevel.gold:
        return AppColors.gold;
      case BadgeLevel.silver:
        return AppColors.silver;
      case BadgeLevel.bronze:
        return AppColors.bronze;
      case BadgeLevel.none:
        return AppColors.primaryOrange;
    }
  }

  String _getBadgeEmoji() {
    switch (widget.badgeLevel) {
      case BadgeLevel.gold:
        return '🥇';
      case BadgeLevel.silver:
        return '🥈';
      case BadgeLevel.bronze:
        return '🥉';
      case BadgeLevel.none:
        return '✓';
    }
  }

  String _getBadgeName() {
    switch (widget.badgeLevel) {
      case BadgeLevel.gold:
        return 'Gold Medal';
      case BadgeLevel.silver:
        return 'Silver Medal';
      case BadgeLevel.bronze:
        return 'Bronze Medal';
      case BadgeLevel.none:
        return 'Completed';
    }
  }

  String _getBadgeDescription() {
    switch (widget.badgeLevel) {
      case BadgeLevel.gold:
        return 'Top 10% performance - Elite level!';
      case BadgeLevel.silver:
        return 'Top 25% performance - Great work!';
      case BadgeLevel.bronze:
        return 'Top 50% performance - Keep improving!';
      case BadgeLevel.none:
        return 'Test completed successfully';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeLevel { gold, silver, bronze, none }

