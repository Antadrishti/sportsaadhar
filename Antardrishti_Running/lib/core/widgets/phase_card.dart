import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'progress_ring.dart';

/// Journey phase card for the dashboard
class PhaseCard extends StatelessWidget {
  final int phaseNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final PhaseStatus status;
  final double progress; // 0.0 to 1.0
  final String? progressLabel; // e.g., "6/10 Tests"
  final VoidCallback? onTap;
  final Color? accentColor;

  const PhaseCard({
    super.key,
    required this.phaseNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.status = PhaseStatus.locked,
    this.progress = 0.0,
    this.progressLabel,
    this.onTap,
    this.accentColor,
  });

  Color get _statusColor {
    switch (status) {
      case PhaseStatus.locked:
        return AppColors.gray400;
      case PhaseStatus.available:
        return accentColor ?? AppColors.primaryOrange;
      case PhaseStatus.inProgress:
        return accentColor ?? AppColors.primaryOrange;
      case PhaseStatus.completed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = status == PhaseStatus.locked;
    final isCompleted = status == PhaseStatus.completed;
    
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked 
              ? AppColors.gray100 
              : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted 
                ? AppColors.success.withOpacity(0.3)
                : status == PhaseStatus.inProgress
                    ? _statusColor.withOpacity(0.3)
                    : AppColors.lightBorder,
            width: status == PhaseStatus.inProgress ? 2 : 1,
          ),
          boxShadow: isLocked
              ? null
              : [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Left side - Phase indicator with progress
            _PhaseIndicator(
              phaseNumber: phaseNumber,
              icon: icon,
              status: status,
              progress: progress,
              color: _statusColor,
            ),
            const SizedBox(width: 16),
            
            // Center - Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Phase $phaseNumber',
                        style: AppTypography.labelSmall.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'COMPLETE',
                            style: AppTypography.overline.copyWith(
                              color: AppColors.success,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: isLocked 
                          ? AppColors.gray500 
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isLocked 
                          ? AppColors.gray400 
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (progressLabel != null && !isLocked) ...[
                    const SizedBox(height: 8),
                    Text(
                      progressLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Right side - Action indicator
            _ActionIndicator(
              status: status,
              color: _statusColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final int phaseNumber;
  final IconData icon;
  final PhaseStatus status;
  final double progress;
  final Color color;

  const _PhaseIndicator({
    required this.phaseNumber,
    required this.icon,
    required this.status,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = status == PhaseStatus.locked;
    final isCompleted = status == PhaseStatus.completed;
    final hasProgress = status == PhaseStatus.inProgress && progress > 0;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring (if in progress)
          if (hasProgress)
            ProgressRing(
              progress: progress,
              size: 60,
              strokeWidth: 4,
              progressColor: color,
              backgroundColor: color.withOpacity(0.2),
            ),
          
          // Icon container
          Container(
            width: hasProgress ? 48 : 56,
            height: hasProgress ? 48 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked 
                  ? AppColors.gray200 
                  : isCompleted 
                      ? AppColors.success.withOpacity(0.1)
                      : color.withOpacity(0.1),
              border: !hasProgress
                  ? Border.all(
                      color: isLocked 
                          ? AppColors.gray300 
                          : color.withOpacity(0.3),
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: isLocked
                  ? const Icon(
                      Icons.lock,
                      color: AppColors.gray400,
                      size: 24,
                    )
                  : isCompleted
                      ? const Icon(
                          Icons.check,
                          color: AppColors.success,
                          size: 28,
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 26,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIndicator extends StatelessWidget {
  final PhaseStatus status;
  final Color color;

  const _ActionIndicator({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PhaseStatus.locked:
        return const Icon(
          Icons.lock_outline,
          color: AppColors.gray400,
          size: 24,
        );
      case PhaseStatus.available:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Start',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        ).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1000.ms,
        );
      case PhaseStatus.inProgress:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue',
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              color: color,
              size: 18,
            ),
          ],
        );
      case PhaseStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 28,
        );
    }
  }
}

/// Compact phase indicator for headers
class PhaseIndicatorCompact extends StatelessWidget {
  final int currentPhase;
  final int totalPhases;

  const PhaseIndicatorCompact({
    super.key,
    required this.currentPhase,
    this.totalPhases = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalPhases, (index) {
        final phase = index + 1;
        final isCompleted = phase < currentPhase;
        final isCurrent = phase == currentPhase;
        
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? AppColors.success 
                    : isCurrent 
                        ? AppColors.primaryOrange
                        : AppColors.gray300,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 14,
                      )
                    : Text(
                        '$phase',
                        style: AppTypography.labelSmall.copyWith(
                          color: isCurrent 
                              ? AppColors.white 
                              : AppColors.gray500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            if (index < totalPhases - 1)
              Container(
                width: 24,
                height: 2,
                color: isCompleted 
                    ? AppColors.success 
                    : AppColors.gray300,
              ),
          ],
        );
      }),
    );
  }
}

enum PhaseStatus {
  locked,
  available,
  inProgress,
  completed,
}

