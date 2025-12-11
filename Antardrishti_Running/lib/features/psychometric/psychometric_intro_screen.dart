import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_button.dart';
import '../../core/widgets/glass_card.dart';
import 'psychometric_question_screen.dart';

/// Psychometric Assessment Intro Screen
class PsychometricIntroScreen extends StatelessWidget {
  const PsychometricIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildDimensions(),
                    const SizedBox(height: 20),
                    _buildRewards(),
                    const SizedBox(height: 30),
                    _buildStartButton(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                color: AppColors.white,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '~10 min',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Brain Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🧠', style: TextStyle(fontSize: 50)),
            ),
          ).animate().scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 24),

          // Title
          Text(
            'Mind Mastery',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 8),

          Text(
            'Psychometric Assessment',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),

          Text(
            'Discover your mental strengths',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return SolidGlassCard(
      padding: const EdgeInsets.all(20),
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
                  Icons.info_outline,
                  color: AppColors.achievementMental,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'What to Expect',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.quiz,
            text: '20 descriptive questions to assess your mindset',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.edit,
            text: 'Share your thoughts in your own words',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.psychology,
            text: 'No right or wrong answers',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.privacy_tip,
            text: 'Your responses are confidential',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildDimensions() {
    final dimensions = [
      _DimensionData('Focus', Icons.center_focus_strong, AppColors.info),
      _DimensionData('Grit', Icons.fitness_center, AppColors.error),
      _DimensionData('Calm', Icons.spa, AppColors.success),
      _DimensionData('Team', Icons.people, AppColors.primaryOrange),
      _DimensionData('Drive', Icons.rocket_launch, AppColors.achievementMental),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What We Measure',
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: dimensions.map((d) {
            return Expanded(
              child: _DimensionChip(dimension: d),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildRewards() {
    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.gold.withValues(alpha: 0.05),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete to Earn',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 16, color: AppColors.primaryOrange),
                    Text(
                      ' +200 XP',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('🏅', style: TextStyle(fontSize: 14)),
                    Text(
                      ' Mind Master Badge',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.achievementMental,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }

  Widget _buildStartButton(BuildContext context) {
    return AnimatedPrimaryButton(
      label: 'Begin Assessment',
      icon: Icons.play_arrow,
      iconAtEnd: true,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PsychometricQuestionScreen(),
          ),
        );
      },
      useGradient: true,
    ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.lightTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DimensionData {
  final String name;
  final IconData icon;
  final Color color;

  const _DimensionData(this.name, this.icon, this.color);
}

class _DimensionChip extends StatelessWidget {
  final _DimensionData dimension;

  const _DimensionChip({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: dimension.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dimension.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(dimension.icon, size: 20, color: dimension.color),
          const SizedBox(height: 4),
          Text(
            dimension.name,
            style: AppTypography.labelSmall.copyWith(
              color: dimension.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

