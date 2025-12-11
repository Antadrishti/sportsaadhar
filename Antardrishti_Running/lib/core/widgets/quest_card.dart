import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Quest card for daily/weekly challenges
class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onClaim;
  final VoidCallback? onTap;

  const QuestCard({
    super.key,
    required this.quest,
    this.onClaim,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: quest.isCompleted
              ? quest.isClaimed
                  ? AppColors.gray100
                  : AppColors.success.withValues(alpha: 0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isCompleted
                ? quest.isClaimed
                    ? AppColors.gray200
                    : AppColors.success.withValues(alpha: 0.3)
                : AppColors.lightBorder,
          ),
          boxShadow: quest.isCompleted && !quest.isClaimed
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: quest.isClaimed
                    ? AppColors.gray200
                    : quest.isCompleted
                        ? AppColors.success
                        : quest.type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: quest.isClaimed
                    ? const Icon(Icons.check, color: AppColors.gray400)
                    : quest.isCompleted
                        ? const Icon(Icons.check, color: AppColors.white)
                        : Text(quest.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _QuestTypeBadge(type: quest.type),
                      const SizedBox(width: 8),
                      if (quest.timeLeft != null)
                        Text(
                          quest.timeLeft!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quest.title,
                    style: AppTypography.titleSmall.copyWith(
                      color: quest.isClaimed
                          ? AppColors.gray400
                          : AppColors.lightTextPrimary,
                      decoration: quest.isClaimed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  if (!quest.isClaimed && quest.progress < 1.0)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: quest.progress,
                              backgroundColor: AppColors.gray200,
                              valueColor: AlwaysStoppedAnimation(
                                quest.isCompleted
                                    ? AppColors.success
                                    : quest.type.color,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${quest.currentProgress}/${quest.targetProgress}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Reward / Claim button
            if (quest.isCompleted && !quest.isClaimed)
              _ClaimButton(
                xp: quest.xpReward,
                coins: quest.coinReward,
                onClaim: () {
                  HapticFeedback.mediumImpact();
                  onClaim?.call();
                },
              )
            else
              _RewardDisplay(
                xp: quest.xpReward,
                coins: quest.coinReward,
                isClaimed: quest.isClaimed,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestTypeBadge extends StatelessWidget {
  final QuestType type;

  const _QuestTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: AppTypography.labelSmall.copyWith(
          color: type.color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final int xp;
  final int? coins;
  final VoidCallback onClaim;

  const _ClaimButton({
    required this.xp,
    this.coins,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClaim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.success, Color(0xFF2E7D32)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Claim',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+$xp',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const Text(' ⚡', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 600.ms),
    );
  }
}

class _RewardDisplay extends StatelessWidget {
  final int xp;
  final int? coins;
  final bool isClaimed;

  const _RewardDisplay({
    required this.xp,
    this.coins,
    this.isClaimed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+$xp',
              style: AppTypography.labelMedium.copyWith(
                color: isClaimed ? AppColors.gray400 : AppColors.primaryOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '⚡',
              style: TextStyle(
                fontSize: 14,
                color: isClaimed ? AppColors.gray400 : null,
              ),
            ),
          ],
        ),
        if (coins != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+$coins',
                style: AppTypography.labelSmall.copyWith(
                  color: isClaimed ? AppColors.gray400 : AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '🪙',
                style: TextStyle(
                  fontSize: 12,
                  color: isClaimed ? AppColors.gray400 : null,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Quest data model
class Quest {
  final String id;
  final String title;
  final String icon;
  final QuestType type;
  final int xpReward;
  final int? coinReward;
  final int currentProgress;
  final int targetProgress;
  final bool isClaimed;
  final String? timeLeft;

  const Quest({
    required this.id,
    required this.title,
    required this.icon,
    required this.type,
    required this.xpReward,
    this.coinReward,
    required this.currentProgress,
    required this.targetProgress,
    this.isClaimed = false,
    this.timeLeft,
  });

  double get progress => currentProgress / targetProgress;
  bool get isCompleted => currentProgress >= targetProgress;
}

enum QuestType {
  daily('Daily', AppColors.primaryOrange),
  weekly('Weekly', AppColors.secondaryPurple),
  special('Special', AppColors.gold),
  achievement('Achievement', AppColors.achievementSpecial);

  final String label;
  final Color color;

  const QuestType(this.label, this.color);
}

/// Quest board showing all quests
class QuestBoard extends StatelessWidget {
  final List<Quest> dailyQuests;
  final List<Quest> weeklyQuests;
  final Function(Quest)? onClaimQuest;

  const QuestBoard({
    super.key,
    required this.dailyQuests,
    required this.weeklyQuests,
    this.onClaimQuest,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('📜', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quest Board',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.secondaryPurple,
                    ),
                  ),
                  Text(
                    'Complete quests to earn rewards!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Daily quests
          _QuestSection(
            title: "Today's Quests",
            subtitle: 'Resets in 12h',
            quests: dailyQuests,
            onClaimQuest: onClaimQuest,
          ),

          const SizedBox(height: 24),

          // Weekly quests
          _QuestSection(
            title: 'Weekly Challenges',
            subtitle: 'Resets in 5d',
            quests: weeklyQuests,
            onClaimQuest: onClaimQuest,
          ),
        ],
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Quest> quests;
  final Function(Quest)? onClaimQuest;

  const _QuestSection({
    required this.title,
    required this.subtitle,
    required this.quests,
    this.onClaimQuest,
  });

  @override
  Widget build(BuildContext context) {
    final completed = quests.where((q) => q.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: completed == quests.length
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$completed/${quests.length}',
                style: AppTypography.labelMedium.copyWith(
                  color: completed == quests.length
                      ? AppColors.success
                      : AppColors.gray600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...quests.asMap().entries.map((entry) {
          final index = entry.key;
          final quest = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: QuestCard(
              quest: quest,
              onClaim: () => onClaimQuest?.call(quest),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
        }),
      ],
    );
  }
}

/// Sample quests for demo
class SampleQuests {
  static final List<Quest> daily = [
    const Quest(
      id: 'd1',
      title: 'Log in to the app',
      icon: '👋',
      type: QuestType.daily,
      xpReward: 10,
      currentProgress: 1,
      targetProgress: 1,
      isClaimed: true,
    ),
    const Quest(
      id: 'd2',
      title: 'Complete 1 physical test',
      icon: '🏃',
      type: QuestType.daily,
      xpReward: 50,
      coinReward: 10,
      currentProgress: 0,
      targetProgress: 1,
    ),
    const Quest(
      id: 'd3',
      title: 'Check the leaderboard',
      icon: '🏆',
      type: QuestType.daily,
      xpReward: 10,
      currentProgress: 1,
      targetProgress: 1,
    ),
  ];

  static final List<Quest> weekly = [
    const Quest(
      id: 'w1',
      title: 'Complete 5 tests this week',
      icon: '💪',
      type: QuestType.weekly,
      xpReward: 200,
      coinReward: 50,
      currentProgress: 2,
      targetProgress: 5,
    ),
    const Quest(
      id: 'w2',
      title: 'Maintain a 5-day streak',
      icon: '🔥',
      type: QuestType.weekly,
      xpReward: 150,
      coinReward: 30,
      currentProgress: 3,
      targetProgress: 5,
    ),
    const Quest(
      id: 'w3',
      title: 'Improve any score',
      icon: '📈',
      type: QuestType.weekly,
      xpReward: 100,
      currentProgress: 0,
      targetProgress: 1,
    ),
  ];
}

