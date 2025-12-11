import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/models/user_progress.dart';
import '../../main.dart';

/// Progress/Analytics screen showing detailed stats
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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
    final progress = appState.progress;

    if (progress == null) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Your Progress'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your progress...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Your Progress'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isRefreshing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshProgress,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProgress,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Journey Progress
              _buildJourneyProgress(progress).animate().fadeIn().slideY(begin: 0.1),
              
              const SizedBox(height: 24),
              
              // Category Scores
              Text(
                'Category Breakdown',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.secondaryPurple,
                ),
              ),
              const SizedBox(height: 16),
              if (progress.categoryScores != null)
                _buildCategoryScores(progress.categoryScores!)
                    .animate().fadeIn(delay: 200.ms).slideY(begin: 0.1)
              else
                const Text('Complete tests to see category breakdown'),
              
              const SizedBox(height: 24),
              
              // Test Results
              Text(
                'Test Results',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.secondaryPurple,
                ),
              ),
              const SizedBox(height: 16),
              if (progress.testProgress.isNotEmpty)
                _buildTestResults(progress.testProgress)
                    .animate().fadeIn(delay: 400.ms).slideY(begin: 0.1)
              else
                const Text('No tests completed yet'),
              
              const SizedBox(height: 24),
              
              // Analysis
              if (progress.categoryScores != null)
                ...[
                  Text(
                    'Analysis',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.secondaryPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAnalysis(progress.categoryScores!)
                      .animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                ],
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyProgress(UserProgress progress) {
    return SolidGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Journey Completion',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PhaseIndicator(
                phase: 1,
                label: 'Physical',
                isComplete: progress.testsCompleted >= progress.totalTests,
                isCurrent: progress.testsCompleted < progress.totalTests,
              ),
              _PhaseConnector(isComplete: progress.testsCompleted >= progress.totalTests),
              _PhaseIndicator(
                phase: 2,
                label: 'Mental',
                isComplete: progress.psychometricCompleted,
                isCurrent: progress.testsCompleted >= progress.totalTests && !progress.psychometricCompleted,
              ),
              _PhaseConnector(isComplete: progress.psychometricCompleted),
              _PhaseIndicator(
                phase: 3,
                label: 'Card',
                isComplete: progress.overallScore != null,
                isCurrent: progress.psychometricCompleted && progress.overallScore == null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScores(CategoryScores scores) {
    final categories = [
      _CategoryData('Strength', scores.strength, AppColors.categoryStrength, Icons.fitness_center),
      _CategoryData('Endurance', scores.endurance, AppColors.categoryEndurance, Icons.directions_run),
      _CategoryData('Flexibility', scores.flexibility, AppColors.categoryFlexibility, Icons.accessibility_new),
      _CategoryData('Agility', scores.agility, AppColors.categoryAgility, Icons.flash_on),
      _CategoryData('Speed', scores.speed, AppColors.categorySpeed, Icons.speed),
    ];

    return Column(
      children: categories
          .map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryScoreBar(category: cat),
              ))
          .toList(),
    );
  }

  Widget _buildTestResults(List<TestProgress> testProgress) {
    // Sort by date (most recent first)
    final sortedTests = List<TestProgress>.from(testProgress)
      ..sort((a, b) {
        final aDate = a.lastAttemptDate;
        final bDate = b.lastAttemptDate;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sortedTests.map((test) => _TestResultRow(testProgress: test)).toList(),
      ),
    );
  }

  Widget _buildAnalysis(CategoryScores scores) {
    // Find strongest and weakest categories
    final categoryValues = {
      'Strength': scores.strength,
      'Endurance': scores.endurance,
      'Flexibility': scores.flexibility,
      'Agility': scores.agility,
      'Speed': scores.speed,
    };

    final nonZeroCategories = categoryValues.entries.where((e) => e.value > 0).toList();
    
    if (nonZeroCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    nonZeroCategories.sort((a, b) => b.value.compareTo(a.value));
    
    final strongest = nonZeroCategories.first;
    final weakest = nonZeroCategories.last;

    return Column(
      children: [
        SolidGlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strongest',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      '${strongest.key} (${strongest.value} pts)',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (nonZeroCategories.length > 1) ...[
          const SizedBox(height: 12),
          SolidGlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.priority_high,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Focus Area',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                      Text(
                        '${weakest.key} (${weakest.value} pts)',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final int phase;
  final String label;
  final bool isComplete;
  final bool isCurrent;

  const _PhaseIndicator({
    required this.phase,
    required this.label,
    required this.isComplete,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? AppColors.success
                : isCurrent
                    ? AppColors.primaryOrange
                    : AppColors.gray300,
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: AppColors.white, size: 24)
                : Text(
                    '$phase',
                    style: AppTypography.titleMedium.copyWith(
                      color: isCurrent ? AppColors.white : AppColors.gray500,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isComplete || isCurrent
                ? AppColors.lightTextPrimary
                : AppColors.gray400,
          ),
        ),
      ],
    );
  }
}

class _PhaseConnector extends StatelessWidget {
  final bool isComplete;

  const _PhaseConnector({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 3,
      margin: const EdgeInsets.only(bottom: 28),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.success : AppColors.gray300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CategoryData {
  final String name;
  final int score;
  final Color color;
  final IconData icon;

  const _CategoryData(this.name, this.score, this.color, this.icon);
}

class _CategoryScoreBar extends StatelessWidget {
  final _CategoryData category;

  const _CategoryScoreBar({required this.category});

  @override
  Widget build(BuildContext context) {
    return SolidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${category.score}',
                style: AppTypography.titleMedium.copyWith(
                  color: category.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: category.score / 100,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(category.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestResultRow extends StatelessWidget {
  final TestProgress testProgress;

  const _TestResultRow({required this.testProgress});

  Color get _ratingColor {
    switch (testProgress.bestRating) {
      case 'platinum':
        return AppColors.achievementSpecial;
      case 'gold':
        return AppColors.gold;
      case 'silver':
        return AppColors.silver;
      case 'bronze':
        return AppColors.bronze;
      default:
        return AppColors.gray400;
    }
  }

  String get _ratingEmoji {
    switch (testProgress.bestRating) {
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

  /// Format score based on test type
  /// For sit and reach, add degree symbol (°)
  String _formatScore(double score) {
    if (testProgress.testId == 'sit_and_reach') {
      return '${score.toStringAsFixed(1)}°';
    }
    return score.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ratingColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testProgress.testName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${testProgress.attempts} attempts${testProgress.lastAttemptDate != null ? ' • ${_formatDate(testProgress.lastAttemptDate!)}' : ''}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _ratingColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _ratingEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatScore(testProgress.bestScore ?? 0),
                    style: AppTypography.labelLarge.copyWith(
                      color: _ratingColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (testProgress.bestPercentile != null)
                    Text(
                      '${testProgress.bestPercentile}%ile',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Show recent attempts if available
          if (testProgress.recentAttempts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: testProgress.recentAttempts.take(3).map((attempt) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatScore(attempt.score),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }
}
