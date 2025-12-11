import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_button.dart';
import '../../core/widgets/confetti_overlay.dart';

/// Sports Aadhaar Card Screen - The final reward
class SportsCardScreen extends StatefulWidget {
  const SportsCardScreen({super.key});

  @override
  State<SportsCardScreen> createState() => _SportsCardScreenState();
}

class _SportsCardScreenState extends State<SportsCardScreen>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  bool _showConfetti = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showConfetti = true);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _flipCard() {
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.1),
                  AppColors.lightBackground,
                  AppColors.secondaryPurple.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.secondaryPurple,
                      ),
                      const Spacer(),
                      Text(
                        'Your Sports Card',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.secondaryPurple,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Celebration Text
                Text(
                  '🎉 Congratulations! 🎉',
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.secondaryPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'You\'ve completed your journey!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // Flip Card
                Expanded(
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(
                          begin: 0,
                          end: _isFlipped ? math.pi : 0,
                        ),
                        builder: (context, value, child) {
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(value),
                            alignment: Alignment.center,
                            child: value < math.pi / 2
                                ? _buildCardFront()
                                : Transform(
                                    transform: Matrix4.identity()..rotateY(math.pi),
                                    alignment: Alignment.center,
                                    child: _buildCardBack(),
                                  ),
                          );
                        },
                      ),
                    ),
                  ).animate().scale(
                        delay: 600.ms,
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      ),
                ),

                // Flip Hint
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tap card to flip',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1200.ms),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedSecondaryButton(
                          label: 'Download',
                          icon: Icons.download,
                          onPressed: () {
                            // Download card
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedPrimaryButton(
                          label: 'Share',
                          icon: Icons.share,
                          onPressed: () {
                            // Share card
                          },
                          useGradient: true,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),
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

  Widget _buildCardFront() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPurple.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.cardPremium,
              ),
            ),

            // Animated Shimmer
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Positioned(
                  left: -200 + (_shimmerController.value * 600),
                  top: 0,
                  bottom: 0,
                  width: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.white.withValues(alpha: 0),
                          AppColors.white.withValues(alpha: 0.3),
                          AppColors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Pattern Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _CardPatternPainter(),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sports_martial_arts,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPORTS AADHAAR',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'Government of India',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Verified Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              color: AppColors.success,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Profile Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo
                      Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.white,
                            width: 3,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Container(
                            color: AppColors.gray200,
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ASMIT SHARMA',
                              style: AppTypography.titleLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _CardInfoRow(
                              label: 'ID',
                              value: 'SAI-2024-127589',
                            ),
                            _CardInfoRow(
                              label: 'Age',
                              value: '19 Years',
                            ),
                            _CardInfoRow(
                              label: 'Valid Until',
                              value: 'Dec 2025',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Scores Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _ScoreBox(
                          label: 'Physical',
                          score: 72,
                          icon: Icons.fitness_center,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                        _ScoreBox(
                          label: 'Mental',
                          score: 78,
                          icon: Icons.psychology,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                        _ScoreBox(
                          label: 'Overall',
                          score: 75,
                          icon: Icons.star,
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Medals
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MedalBadge(emoji: '🥇', count: 4),
                      const SizedBox(width: 12),
                      _MedalBadge(emoji: '🥈', count: 3),
                      const SizedBox(width: 12),
                      _MedalBadge(emoji: '🥉', count: 3),
                    ],
                  ),

                  const Spacer(),

                  // Footer
                  Center(
                    child: Text(
                      'Rank #127 • Level 4 Rising Star',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPurple.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gray800,
                AppColors.gray900,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Magnetic Stripe
                Container(
                  height: 50,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: AppColors.gray700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 30),

                // QR Code
                Container(
                  width: 140,
                  height: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    size: const Size(116, 116),
                    painter: _QRCodePainter(),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Scan to verify',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 30),

                // Stats Grid
                _buildBackStats(),

                const Spacer(),

                // Footer
                Text(
                  'This card is property of SAI. If found, please return.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'www.sportsaadhaar.gov.in',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackStats() {
    final stats = [
      ('Tests', '10/10'),
      ('XP', '1,250'),
      ('Badges', '12'),
      ('Streak', '5 days'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: stats.map((stat) {
        return Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                stat.$2,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                stat.$1,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CardInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;
  final bool isHighlight;

  const _ScoreBox({
    required this.label,
    required this.score,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: isHighlight
                ? AppColors.gold
                : AppColors.white.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: AppTypography.titleMedium.copyWith(
              color: isHighlight ? AppColors.gold : AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalBadge extends StatelessWidget {
  final String emoji;
  final int count;

  const _MedalBadge({required this.emoji, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '×$count',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Card Pattern Painter
class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw subtle circles
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8 + i * 30, size.height * 0.3 - i * 20),
        60 + i * 20,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simplified QR Code Painter
class _QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray900
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 21;
    final random = math.Random(42); // Fixed seed for consistent pattern

    // Draw QR-like pattern
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        // Position markers (corners)
        final isPositionMarker = (i < 7 && j < 7) ||
            (i < 7 && j > 13) ||
            (i > 13 && j < 7);

        if (isPositionMarker || random.nextBool()) {
          canvas.drawRect(
            Rect.fromLTWH(
              i * cellSize,
              j * cellSize,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

