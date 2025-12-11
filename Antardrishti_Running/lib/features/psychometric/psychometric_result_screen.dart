import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_button.dart';
import '../../core/widgets/confetti_overlay.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/models/psychometric_test.dart';

/// Psychometric Result Screen - Shows 70% hardcoded score with detailed breakdown
class PsychometricResultScreen extends StatefulWidget {
  final PsychometricResult result;
  final int xpEarned;
  final dynamic levelUp;
  final List unlockedAchievements;

  const PsychometricResultScreen({
    super.key,
    required this.result,
    required this.xpEarned,
    this.levelUp,
    this.unlockedAchievements = const [],
  });

  @override
  State<PsychometricResultScreen> createState() =>
      _PsychometricResultScreenState();
}

class _PsychometricResultScreenState extends State<PsychometricResultScreen>
    with SingleTickerProviderStateMixin {
  bool _showConfetti = false;
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _radarAnimation = CurvedAnimation(
      parent: _radarController,
      curve: Curves.easeOutCubic,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _radarController.forward();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _showConfetti = true);
      });
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildRadarChart(),
                        const SizedBox(height: 24),
                        _buildDimensionCards(),
                        const SizedBox(height: 24),
                        _buildInsights(),
                        const SizedBox(height: 24),
                        _buildRewards(),
                        const SizedBox(height: 24),
                        _buildActions(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          if (_showConfetti)
            ConfettiOverlay(
              isActive: _showConfetti,
              onComplete: () {
                if (mounted) setState(() => _showConfetti = false);
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
      decoration: const BoxDecoration(
        gradient: AppGradients.mentalPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          // App Bar
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                ),
                icon: const Icon(Icons.close),
                color: AppColors.white,
              ),
              const Spacer(),
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
              ).animate(delay: 2000.ms).fadeIn().scale(),
            ],
          ),

          const SizedBox(height: 20),

          // Success Badge
          if (widget.unlockedAchievements.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🏅 Mind Master Badge Earned!',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ).animate(delay: 1500.ms).fadeIn().slideY(begin: -0.2),

          const SizedBox(height: 20),

          // Title
          Text(
            'Assessment Complete!',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 24),

          // Overall Score
          ScoreRing(
            score: widget.result.overallScore,
            label: 'Mental Score',
            size: 140,
            color: AppColors.white,
          ).animate(delay: 500.ms).scale(curve: Curves.elasticOut),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    final sections = ['Mental\nToughness', 'Focus', 'Stress\nMgmt', 'Teamwork'];
    final values = [
      widget.result.sectionScores['mental_toughness']?.toDouble() ?? 70.0,
      widget.result.sectionScores['focus']?.toDouble() ?? 70.0,
      widget.result.sectionScores['stress']?.toDouble() ?? 70.0,
      widget.result.sectionScores['teamwork']?.toDouble() ?? 70.0,
    ];

    return SolidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mental Profile',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, 220),
                  painter: _RadarChartPainter(
                    dimensions: sections,
                    values: values
                        .map((v) => (v / 100) * _radarAnimation.value)
                        .toList(),
                    maxValue: 1.0,
                    color: AppColors.achievementMental,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildDimensionCards() {
    final dimensionData = [
      _DimensionInfo(
        'Mental Toughness',
        'mental_toughness',
        Icons.fitness_center,
        AppColors.error,
        'Your resilience and perseverance',
      ),
      _DimensionInfo(
        'Focus & Concentration',
        'focus',
        Icons.center_focus_strong,
        AppColors.info,
        'Your ability to stay present and concentrated',
      ),
      _DimensionInfo(
        'Stress Management',
        'stress',
        Icons.spa,
        AppColors.success,
        'Your ability to manage pressure and stay calm',
      ),
      _DimensionInfo(
        'Team Collaboration',
        'teamwork',
        Icons.people,
        AppColors.primaryOrange,
        'Your teamwork and communication skills',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Breakdown',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...dimensionData.asMap().entries.map((entry) {
          final index = entry.key;
          final dim = entry.value;
          final score = widget.result.sectionScores[dim.key] ?? 70;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DimensionCard(
              dimension: dim,
              score: score,
            ),
          ).animate(delay: Duration(milliseconds: 900 + (index * 100))).fadeIn().slideX(begin: 0.1);
        }),
      ],
    );
  }

  Widget _buildInsights() {
    return SolidGlassCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.achievementMental.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.achievementMental.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppColors.achievementMental,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Insights',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Excellent Performance!',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your responses show strong mental qualities across all dimensions. '
            'You demonstrate good self-awareness, emotional control, and a growth mindset. '
            'Continue developing these mental skills through practice and reflection.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate(delay: 1400.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildRewards() {
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
                  'Rewards Earned',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 16, color: AppColors.primaryOrange),
                    Text(
                      ' ${widget.xpEarned} XP',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('🧠', style: TextStyle(fontSize: 14)),
                    Text(
                      ' Mind Master',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.achievementMental,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 1600.ms).fadeIn().shake(hz: 2, rotation: 0.02);
  }

  Widget _buildActions() {
    return Column(
      children: [
        AnimatedPrimaryButton(
          label: 'Get Your Sports Card',
          icon: Icons.card_membership,
          iconAtEnd: true,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/sports-card');
          },
          useGradient: true,
        ),
        const SizedBox(height: 12),
        AnimatedSecondaryButton(
          label: 'Back to Home',
          icon: Icons.home,
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ],
    ).animate(delay: 1800.ms).fadeIn();
  }
}

class _DimensionInfo {
  final String name;
  final String key;
  final IconData icon;
  final Color color;
  final String description;

  const _DimensionInfo(this.name, this.key, this.icon, this.color, this.description);
}

class _DimensionCard extends StatelessWidget {
  final _DimensionInfo dimension;
  final int score;

  const _DimensionCard({
    required this.dimension,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dimension.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(dimension.icon, color: dimension.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dimension.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dimension.description,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(dimension.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$score',
            style: AppTypography.titleMedium.copyWith(
              color: dimension.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Radar Chart Painter
class _RadarChartPainter extends CustomPainter {
  final List<String> dimensions;
  final List<double> values;
  final double maxValue;
  final Color color;

  _RadarChartPainter({
    required this.dimensions,
    required this.values,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final angleStep = (2 * math.pi) / dimensions.length;

    // Draw background circles
    final bgPaint = Paint()
      ..color = AppColors.gray200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, bgPaint);
    }

    // Draw axis lines
    for (int i = 0; i < dimensions.length; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), bgPaint);

      // Draw labels
      final labelX = center.dx + (radius + 25) * math.cos(angle);
      final labelY = center.dy + (radius + 25) * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: dimensions[i],
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.lightTextSecondary,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 60);
      textPainter.paint(
        canvas,
        Offset(
          labelX - textPainter.width / 2,
          labelY - textPainter.height / 2,
        ),
      );
    }

    // Draw data area
    if (values.isNotEmpty && values.every((v) => v > 0)) {
      final path = Path();
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < values.length; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        final value = values[i] / maxValue;
        final x = center.dx + radius * value * math.cos(angle);
        final y = center.dy + radius * value * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        // Draw data points
        canvas.drawCircle(
          Offset(x, y),
          5,
          Paint()..color = color,
        );
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
