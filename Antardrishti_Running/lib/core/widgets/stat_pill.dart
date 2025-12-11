import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Pill-shaped stat display widget
class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? textColor;
  final bool compact;

  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.textColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? 
        (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant);
    final txtColor = textColor ?? 
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: iconColor ?? AppColors.primaryOrange,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: (compact ? AppTypography.labelMedium : AppTypography.labelLarge)
                    .copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: txtColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal stat pill row
class StatPillRow extends StatelessWidget {
  final List<StatPillData> stats;
  final bool compact;

  const StatPillRow({
    super.key,
    required this.stats,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4),
            child: StatPill(
              label: stat.label,
              value: stat.value,
              icon: stat.icon,
              iconColor: stat.iconColor,
              backgroundColor: stat.backgroundColor,
              compact: compact,
            ),
          ).animate(delay: Duration(milliseconds: 100 * index))
              .fadeIn()
              .slideX(begin: -0.1),
        );
      }).toList(),
    );
  }
}

/// Data class for stat pill
class StatPillData {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const StatPillData({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor,
  });
}

/// Circular stat indicator
class CircularStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final double size;

  const CircularStat({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.primaryOrange,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

/// Large stat card with icon
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppColors.primaryOrange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? AppColors.darkBorder.withOpacity(0.3) 
                  : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTypography.headlineSmall.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


