import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';

/// Gamified dialog shown after completing each section
class SectionCompletionDialog extends StatelessWidget {
  final int sectionNumber;
  final int totalSections;
  final String sectionTitle;
  final IconData sectionIcon;
  final Color sectionColor;

  const SectionCompletionDialog({
    super.key,
    required this.sectionNumber,
    required this.totalSections,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti/celebration effects
        _buildCelebrationEffects(),
        
        // Main card
        SolidGlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      sectionColor.withValues(alpha: 0.3),
                      sectionColor.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sectionIcon,
                  size: 50,
                  color: sectionColor,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    duration: 1000.ms,
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 24),

              // Success emoji
              Text(
                '🎉',
                style: const TextStyle(fontSize: 48),
              ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 16),

              // Completion message
              Text(
                'Section $sectionNumber Complete!',
                style: AppTypography.headlineSmall.copyWith(
                  color: sectionColor,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                sectionTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Progress indicator
              _buildProgressIndicator().animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sectionColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        sectionNumber < totalSections
                            ? 'Continue to Next Section'
                            : 'View Results',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        sectionNumber < totalSections
                            ? Icons.arrow_forward
                            : Icons.check_circle,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
            ],
          ),
        ).animate().scale(
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),
      ],
    );
  }

  Widget _buildCelebrationEffects() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        children: [
          // Floating particles
          ..._buildParticles(),
        ],
      ),
    );
  }

  List<Widget> _buildParticles() {
    final particles = <Widget>[];
    final colors = [
      AppColors.gold,
      AppColors.primaryOrange,
      sectionColor,
      AppColors.achievementMental,
      AppColors.success,
    ];

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30.0) * (3.14159 / 180);
      final distance = 100.0 + (i % 3) * 20;

      particles.add(
        Positioned(
          left: 150 + distance * (i % 2 == 0 ? 1 : -1),
          top: 150 + distance * ((i ~/ 3) % 2 == 0 ? 1 : -1),
          child: Container(
            width: 8 + (i % 3) * 2,
            height: 8 + (i % 3) * 2,
            decoration: BoxDecoration(
              color: colors[i % colors.length],
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .moveY(
                begin: 0,
                end: -20 - (i % 3) * 5,
                duration: Duration(milliseconds: 1000 + i * 100),
                curve: Curves.easeInOut,
              )
              .fadeOut(
                begin: 0.8,
                duration: Duration(milliseconds: 1000 + i * 100),
              ),
        ),
      );
    }

    return particles;
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sectionColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Progress: $sectionNumber of $totalSections sections',
                style: AppTypography.labelLarge.copyWith(
                  color: sectionColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: List.generate(
              totalSections,
              (index) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < totalSections - 1 ? 8 : 0,
                  ),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index < sectionNumber
                        ? sectionColor
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${((sectionNumber / totalSections) * 100).toInt()}% Complete',
            style: AppTypography.labelMedium.copyWith(
              color: sectionColor,
            ),
          ),
        ],
      ),
    );
  }
}
