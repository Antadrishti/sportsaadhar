import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Animated score counter with number roll effect
class ScoreCounter extends StatefulWidget {
  final int score;
  final int? maxScore;
  final String? suffix;
  final String? prefix;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final bool showAnimation;

  const ScoreCounter({
    super.key,
    required this.score,
    this.maxScore,
    this.suffix,
    this.prefix,
    this.style,
    this.duration = const Duration(milliseconds: 1500),
    this.curve = Curves.easeOutCubic,
    this.color,
    this.showAnimation = true,
  });

  @override
  State<ScoreCounter> createState() => _ScoreCounterState();
}

class _ScoreCounterState extends State<ScoreCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _displayScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ))
      ..addListener(() {
        setState(() {
          _displayScore = _animation.value.toInt();
        });
      });

    if (widget.showAnimation) {
      _controller.forward();
    } else {
      _displayScore = widget.score;
    }
  }

  @override
  void didUpdateWidget(ScoreCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _displayScore.toDouble(),
        end: widget.score.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
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
    final textStyle = widget.style ?? AppTypography.scoreDisplay;
    final textColor = widget.color ?? AppColors.primaryOrange;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (widget.prefix != null)
          Text(
            widget.prefix!,
            style: textStyle.copyWith(
              color: textColor,
              fontSize: (textStyle.fontSize ?? 64) * 0.5,
            ),
          ),
        Text(
          '$_displayScore',
          style: textStyle.copyWith(color: textColor),
        ),
        if (widget.maxScore != null)
          Text(
            '/${widget.maxScore}',
            style: textStyle.copyWith(
              color: textColor.withOpacity(0.5),
              fontSize: (textStyle.fontSize ?? 64) * 0.4,
            ),
          ),
        if (widget.suffix != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.suffix!,
              style: textStyle.copyWith(
                color: textColor.withOpacity(0.7),
                fontSize: (textStyle.fontSize ?? 64) * 0.3,
              ),
            ),
          ),
      ],
    );
  }
}

/// Timer display with animated countdown
class TimerDisplay extends StatefulWidget {
  final Duration duration;
  final bool isCountdown;
  final bool isRunning;
  final VoidCallback? onComplete;
  final TextStyle? style;
  final Color? color;

  const TimerDisplay({
    super.key,
    required this.duration,
    this.isCountdown = true,
    this.isRunning = true,
    this.onComplete,
    this.style,
    this.color,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with SingleTickerProviderStateMixin {
  late Duration _currentDuration;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.duration;
    if (widget.isRunning) {
      _startTimer();
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !widget.isRunning) return;
      
      setState(() {
        if (widget.isCountdown) {
          _currentDuration -= const Duration(seconds: 1);
          if (_currentDuration.inSeconds <= 0) {
            widget.onComplete?.call();
            return;
          }
        } else {
          _currentDuration += const Duration(seconds: 1);
        }
      });
      _startTimer();
    });
  }

  @override
  void didUpdateWidget(TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _currentDuration = widget.duration;
    }
    if (widget.isRunning && !oldWidget.isRunning) {
      _startTimer();
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ?? AppTypography.timer;
    final textColor = widget.color ?? AppColors.primaryOrange;

    return Text(
      _formatDuration(_currentDuration),
      style: textStyle.copyWith(color: textColor),
    );
  }
}

/// Large score reveal with celebration
class ScoreReveal extends StatefulWidget {
  final int score;
  final int maxScore;
  final String label;
  final String? badge; // "Gold", "Silver", "Bronze"
  final String? percentile; // "Better than 89% of your age!"
  final VoidCallback? onAnimationComplete;

  const ScoreReveal({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.label = 'Score',
    this.badge,
    this.percentile,
    this.onAnimationComplete,
  });

  @override
  State<ScoreReveal> createState() => _ScoreRevealState();
}

class _ScoreRevealState extends State<ScoreReveal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _scaleController.forward();
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    final percentage = widget.score / widget.maxScore;
    if (percentage >= 0.8) return AppColors.goldBadge;
    if (percentage >= 0.6) return AppColors.silver;
    return AppColors.bronze;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Score number
                ScoreCounter(
                  score: widget.score,
                  maxScore: widget.maxScore,
                  color: _scoreColor,
                  style: AppTypography.scoreDisplay,
                ),
                const SizedBox(height: 8),
                
                // Label
                Text(
                  widget.label,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                
                // Badge
                if (widget.badge != null) ...[
                  const SizedBox(height: 16),
                  _BadgeDisplay(badge: widget.badge!),
                ],
                
                // Percentile
                if (widget.percentile != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.percentile!,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BadgeDisplay extends StatelessWidget {
  final String badge;

  const _BadgeDisplay({required this.badge});

  Color get _badgeColor {
    switch (badge.toLowerCase()) {
      case 'gold':
        return AppColors.goldBadge;
      case 'silver':
        return AppColors.silver;
      case 'bronze':
        return AppColors.bronze;
      default:
        return AppColors.primaryOrange;
    }
  }

  String get _badgeEmoji {
    switch (badge.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_badgeEmoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 8),
        Text(
          badge.toUpperCase(),
          style: AppTypography.titleLarge.copyWith(
            color: _badgeColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(_badgeEmoji, style: const TextStyle(fontSize: 32)),
      ],
    );
  }
}

/// XP reward toast that floats up
class XPRewardToast extends StatefulWidget {
  final int xpAmount;
  final String? reason;
  final VoidCallback? onComplete;

  const XPRewardToast({
    super.key,
    required this.xpAmount,
    this.reason,
    this.onComplete,
  });

  @override
  State<XPRewardToast> createState() => _XPRewardToastState();
}

class _XPRewardToastState extends State<XPRewardToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bolt,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.xpAmount} XP',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.reason != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.reason!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


