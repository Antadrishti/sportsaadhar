import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular progress ring with customizable appearance
class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? backgroundColor;
  final Widget? child;
  final bool animate;
  final Duration animationDuration;
  final bool showPercentage;
  final Gradient? gradient;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.progressColor,
    this.backgroundColor,
    this.child,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1000),
    this.showPercentage = false,
    this.gradient,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ?? 
        (isDark ? AppColors.darkSurfaceVariant : AppColors.gray200);
    final progressColor = widget.progressColor ?? AppColors.primaryOrange;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: bgColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Progress ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: _progressAnimation.value,
                  color: progressColor,
                  strokeWidth: widget.strokeWidth,
                  gradient: widget.gradient,
                ),
              ),
              // Center content
              if (widget.child != null)
                widget.child!
              else if (widget.showPercentage)
                Text(
                  '${(_progressAnimation.value * 100).toInt()}%',
                  style: AppTypography.titleLarge.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final Gradient? gradient;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (gradient != null) {
      paint.shader = gradient!.createShader(rect);
    } else {
      paint.color = color;
    }

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Progress ring with score display
class ScoreRing extends StatelessWidget {
  final int score;
  final int maxScore;
  final String label;
  final double size;
  final Color? color;

  const ScoreRing({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.label = '',
    this.size = 100,
    this.color,
  });

  Color get _scoreColor {
    if (color != null) return color!;
    final percentage = score / maxScore;
    if (percentage >= 0.8) return AppColors.success;
    if (percentage >= 0.6) return AppColors.primaryOrange;
    if (percentage >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(
          progress: score / maxScore,
          size: size,
          strokeWidth: size * 0.1,
          progressColor: _scoreColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: AppTypography.scoreSmall.copyWith(
                  color: _scoreColor,
                  fontSize: size * 0.28,
                ),
              ),
              Text(
                '/$maxScore',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gray500,
                  fontSize: size * 0.1,
                ),
              ),
            ],
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Multiple concentric progress rings
class MultiRing extends StatelessWidget {
  final List<RingData> rings;
  final double size;

  const MultiRing({
    super.key,
    required this.rings,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: rings.asMap().entries.map((entry) {
          final index = entry.key;
          final ring = entry.value;
          final ringSize = size - (index * 30);
          
          return ProgressRing(
            progress: ring.progress,
            size: ringSize,
            strokeWidth: 8,
            progressColor: ring.color,
            animate: true,
            animationDuration: Duration(milliseconds: 1000 + (index * 200)),
          );
        }).toList(),
      ),
    );
  }
}

class RingData {
  final double progress;
  final Color color;
  final String? label;

  const RingData({
    required this.progress,
    required this.color,
    this.label,
  });
}

/// Small inline progress indicator
class MiniProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;

  const MiniProgressRing({
    super.key,
    required this.progress,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressRing(
      progress: progress,
      size: size,
      strokeWidth: 3,
      progressColor: color ?? AppColors.primaryOrange,
      animate: false,
    );
  }
}


