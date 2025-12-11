import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/models/user_progress.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/phase_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/streak_calendar.dart';
import '../../core/widgets/xp_progress_bar.dart';
import '../../main.dart';

/// Journey Dashboard - The new home screen
/// Shows the athlete's progress through their journey
class JourneyDashboard extends StatefulWidget {
  const JourneyDashboard({super.key});

  @override
  State<JourneyDashboard> createState() => _JourneyDashboardState();
}

class _JourneyDashboardState extends State<JourneyDashboard> {
  bool _isRefreshing = false;

  Future<void> _refreshProgress() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    try {
      await context.read<AppState>().refreshProgress();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final progress = appState.progress;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: progress == null
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _refreshProgress,
                child: CustomScrollView(
                  slivers: [
                    // Header with user info and XP
                    SliverToBoxAdapter(
                      child: _buildHeader(user?.name ?? 'Athlete', progress),
                    ),

                    // Streak Calendar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: StreakCalendar(
                          currentStreak: progress.streak,
                          weekDays: progress.weekStreak,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Journey Progress Overview
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildJourneyOverview(progress),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Phase Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Journey',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.secondaryPurple,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPhaseCards(progress),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Quick Stats
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildQuickStats(progress),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // Daily Challenges
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDailyChallenges(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your progress...'),
        ],
      ),
    );
  }

  Widget _buildHeader(String userName, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: AppGradients.dashboardHeader,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome row
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                  color: AppColors.white.withValues(alpha: 0.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      userName,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Settings button
              IconButton(
                onPressed: () {
                  // Navigate to settings
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.white,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 20),

          // XP Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: XPProgressBar(
              currentXP: progress.currentXP,
              currentLevel: progress.currentLevel,
              xpForCurrentLevel: progress.xpForCurrentLevel,
              xpForNextLevel: progress.xpForNextLevel,
              levelTitle: progress.levelTitle,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildJourneyOverview(UserProgress progress) {
    return SolidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress Ring
          ProgressRing(
            progress: progress.journeyProgress,
            size: 80,
            strokeWidth: 8,
            progressColor: AppColors.primaryOrange,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress.journeyProgress * 100).toInt()}%',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey Progress',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.testsCompleted}/${progress.totalTests} Tests • ${progress.psychometricCompleted ? '✓' : '○'} Mental',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getJourneyStatusText(progress),
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  String _getJourneyStatusText(UserProgress progress) {
    if (progress.testsCompleted < progress.totalTests) {
      return '${progress.totalTests - progress.testsCompleted} tests remaining';
    }
    if (!progress.psychometricCompleted) {
      return 'Ready for mental assessment';
    }
    if (progress.overallScore == null) {
      return 'Generate your card!';
    }
    return 'Journey complete! 🎉';
  }

  Widget _buildPhaseCards(UserProgress progress) {
    return Column(
      children: [
        PhaseCard(
          phaseNumber: 1,
          title: 'Physical Trials',
          subtitle: 'Complete 10 physical assessments',
          icon: Icons.fitness_center,
          status: progress.testsCompleted >= progress.totalTests
              ? PhaseStatus.completed
              : progress.testsCompleted > 0
                  ? PhaseStatus.inProgress
                  : PhaseStatus.available,
          progress: progress.testCompletionProgress,
          progressLabel: '${progress.testsCompleted}/${progress.totalTests} Complete',
          onTap: () => Navigator.pushNamed(context, '/physical-assessment'),
          accentColor: AppColors.categoryStrength,
        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
        
        const SizedBox(height: 12),
        
        PhaseCard(
          phaseNumber: 2,
          title: 'Mind Mastery',
          subtitle: 'Psychometric assessment',
          icon: Icons.psychology,
          status: progress.testsCompleted < progress.totalTests
              ? PhaseStatus.locked
              : progress.psychometricCompleted
                  ? PhaseStatus.completed
                  : PhaseStatus.available,
          progress: progress.psychometricCompleted ? 1.0 : 0.0,
          progressLabel: progress.psychometricCompleted ? 'Complete' : null,
          onTap: progress.testsCompleted >= progress.totalTests
              ? () => Navigator.pushNamed(context, '/psychometric')
              : null,
          accentColor: AppColors.achievementMental,
        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
        
        const SizedBox(height: 12),
        
        PhaseCard(
          phaseNumber: 3,
          title: 'Your Card',
          subtitle: 'Get your Sports Aadhaar Card',
          icon: Icons.card_membership,
          status: !progress.psychometricCompleted
              ? PhaseStatus.locked
              : progress.overallScore != null
                  ? PhaseStatus.completed
                  : PhaseStatus.available,
          progress: progress.overallScore != null ? 1.0 : 0.0,
          onTap: progress.psychometricCompleted
              ? () => Navigator.pushNamed(context, '/sports-card')
              : null,
          accentColor: AppColors.gold,
        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
      ],
    );
  }

  Widget _buildQuickStats(UserProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.secondaryPurple,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.emoji_events,
                value: '#${progress.rank ?? '-'}',
                label: 'Rank',
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.bolt,
                value: '${progress.currentXP}',
                label: 'Total XP',
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.workspace_premium,
                value: '${progress.unlockedAchievements.length}',
                label: 'Badges',
                color: AppColors.achievementSpecial,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }

  Widget _buildDailyChallenges() {
    // Mock challenges
    final challenges = [
      const _ChallengeData(
        title: 'Daily Login',
        xp: 10,
        isCompleted: true,
        icon: Icons.login,
      ),
      const _ChallengeData(
        title: 'Complete 1 Test',
        xp: 50,
        isCompleted: false,
        icon: Icons.assignment,
      ),
      const _ChallengeData(
        title: 'Share Score',
        xp: 20,
        isCompleted: false,
        icon: Icons.share,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Challenges",
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.secondaryPurple,
              ),
            ),
            Text(
              '${challenges.where((c) => c.isCompleted).length}/${challenges.length}',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primaryOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: challenges.asMap().entries.map((entry) {
            final index = entry.key;
            final challenge = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == challenges.length - 1 ? 0 : 6,
                ),
                child: _ChallengeCard(challenge: challenge),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
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

class _ChallengeData {
  final String title;
  final int xp;
  final bool isCompleted;
  final IconData icon;

  const _ChallengeData({
    required this.title,
    required this.xp,
    required this.isCompleted,
    required this.icon,
  });
}

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData challenge;

  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: challenge.isCompleted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: challenge.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            challenge.isCompleted ? Icons.check_circle : challenge.icon,
            color: challenge.isCompleted
                ? AppColors.success
                : AppColors.primaryOrange,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            '+${challenge.xp}',
            style: AppTypography.labelLarge.copyWith(
              color: challenge.isCompleted
                  ? AppColors.success
                  : AppColors.primaryOrange,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'XP',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            challenge.title,
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

