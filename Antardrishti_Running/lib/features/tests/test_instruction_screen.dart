import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_button.dart';
import '../../core/widgets/glass_card.dart';

/// Test Instruction Screen - Shown before starting any test
class TestInstructionScreen extends StatelessWidget {
  final String testName;
  final String testDescription;
  final IconData testIcon;
  final List<String> requirements;
  final List<InstructionStep> steps;
  final List<String> tips;
  final int xpReward;
  final String? badgeReward;
  final VoidCallback onStart;

  const TestInstructionScreen({
    super.key,
    required this.testName,
    required this.testDescription,
    required this.testIcon,
    required this.requirements,
    required this.steps,
    required this.tips,
    this.xpReward = 50,
    this.badgeReward,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: _buildHeroHeader(context),
          ),

          // Requirements Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildRequirements(),
            ),
          ),

          // How It Works Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildHowItWorks(),
            ),
          ),

          // Pro Tips Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildProTips(),
            ),
          ),

          // Rewards Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _buildRewards(),
            ),
          ),

          // Start Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildStartButton(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryOrangeSubtle,
      ),
      child: SafeArea(
        bottom: false,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          size: 16,
                          color: AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+$xpReward XP',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Test Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.primaryOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                testIcon,
                size: 48,
                color: AppColors.white,
              ),
            ).animate().scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 20),

            // Test Name
            Text(
              testName,
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.secondaryPurple,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                testDescription,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.checklist,
          title: 'What You\'ll Need',
          color: AppColors.info,
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        SolidGlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: requirements.asMap().entries.map((entry) {
              final index = entry.key;
              final requirement = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < requirements.length - 1 ? 12 : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        requirement,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.play_circle_outline,
          title: 'How It Works',
          color: AppColors.primaryOrange,
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 12),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == steps.length - 1 ? 0 : 6,
                ),
                child: _StepCard(
                  stepNumber: index + 1,
                  title: step.title,
                  description: step.description,
                  icon: step.icon,
                ),
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildProTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.lightbulb_outline,
          title: 'Pro Tips',
          color: AppColors.warning,
        ).animate().fadeIn(delay: 800.ms),
        const SizedBox(height: 12),
        SolidGlassCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppColors.warning.withValues(alpha: 0.05),
          child: Column(
            children: tips.asMap().entries.map((entry) {
              final index = entry.key;
              final tip = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < tips.length - 1 ? 12 : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.card_giftcard,
          title: 'Potential Rewards',
          color: AppColors.gold,
        ).animate().fadeIn(delay: 1000.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RewardCard(
                icon: Icons.bolt,
                value: '+$xpReward',
                label: 'XP',
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RewardCard(
                icon: Icons.emoji_events,
                value: badgeReward ?? 'Gold',
                label: 'Badge',
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RewardCard(
                icon: Icons.trending_up,
                value: '+Rank',
                label: 'Leaderboard',
                color: AppColors.success,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildStartButton() {
    return AnimatedPrimaryButton(
      label: "I'm Ready - Start Test",
      icon: Icons.play_arrow,
      iconAtEnd: true,
      onPressed: onStart,
      useGradient: true,
    ).animate().fadeIn(delay: 1200.ms).scale(
          begin: const Offset(0.95, 0.95),
        );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryOrangeSubtle,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryOrange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Icon(icon, size: 24, color: AppColors.primaryOrange),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RewardCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: color,
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

class InstructionStep {
  final String title;
  final String description;
  final IconData icon;

  const InstructionStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

