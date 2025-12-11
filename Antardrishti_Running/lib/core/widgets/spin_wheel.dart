import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'confetti_overlay.dart';

/// Lucky spin wheel widget
class SpinWheel extends StatefulWidget {
  final List<WheelSegment> segments;
  final VoidCallback? onSpinComplete;
  final Function(WheelSegment)? onWin;
  final bool canSpin;

  const SpinWheel({
    super.key,
    required this.segments,
    this.onSpinComplete,
    this.onWin,
    this.canSpin = true,
  });

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;
  WheelSegment? _winner;
  double _currentRotation = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || !widget.canSpin) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    // Calculate random winner based on probability
    final random = Random();
    double roll = random.nextDouble();
    double cumulative = 0;
    WheelSegment winner = widget.segments.first;

    for (final segment in widget.segments) {
      cumulative += segment.probability;
      if (roll <= cumulative) {
        winner = segment;
        break;
      }
    }

    // Calculate rotation to land on winner
    final segmentAngle = 2 * pi / widget.segments.length;
    final winnerIndex = widget.segments.indexOf(winner);
    final targetAngle = -segmentAngle * winnerIndex - segmentAngle / 2;

    // Add extra rotations for effect
    final extraRotations = 5 + random.nextInt(3);
    final totalRotation = extraRotations * 2 * pi + targetAngle - _currentRotation;

    _animation = Tween<double>(
      begin: 0,
      end: totalRotation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _animation.addListener(() {
      setState(() {
        _currentRotation += _animation.value - (_controller.value > 0 ? totalRotation * (_controller.value - _controller.value.floorToDouble() / _controller.value) : 0);
      });
    });

    _controller.forward(from: 0).then((_) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isSpinning = false;
        _winner = winner;
        _currentRotation = targetAngle;
      });
      widget.onWin?.call(winner);
      widget.onSpinComplete?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pointer
        Transform.translate(
          offset: const Offset(0, 8),
          child: Icon(
            Icons.arrow_drop_down,
            size: 48,
            color: AppColors.secondaryPurple,
          ),
        ),

        // Wheel
        Stack(
          alignment: Alignment.center,
          children: [
            // Wheel background
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _currentRotation + (_animation.value * (_controller.isAnimating ? 1 : 0)),
                  child: CustomPaint(
                    size: const Size(280, 280),
                    painter: _WheelPainter(segments: widget.segments),
                  ),
                );
              },
            ),

            // Center button
            GestureDetector(
              onTap: widget.canSpin ? _spin : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSpinning
                      ? AppColors.gray400
                      : widget.canSpin
                          ? AppColors.primaryOrange
                          : AppColors.gray300,
                  boxShadow: [
                    BoxShadow(
                      color: (_isSpinning || !widget.canSpin
                              ? AppColors.gray400
                              : AppColors.primaryOrange)
                          .withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSpinning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          'SPIN',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Result display
        if (_winner != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _winner!.color.withValues(alpha: 0.2),
                  _winner!.color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _winner!.color.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _winner!.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You won!',
                      style: AppTypography.labelSmall.copyWith(
                        color: _winner!.color,
                      ),
                    ),
                    Text(
                      _winner!.label,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(),
      ],
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<WheelSegment> segments;

  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;
      final segment = segments[i];

      // Draw segment
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Draw icon
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + segmentAngle / 2);
      canvas.translate(radius * 0.65, 0);
      canvas.rotate(-startAngle - segmentAngle / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: segment.icon,
          style: const TextStyle(fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      45,
      Paint()..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) => false;
}

class WheelSegment {
  final String label;
  final String icon;
  final Color color;
  final double probability;
  final int? xpReward;
  final int? coinReward;
  final String? specialReward;

  const WheelSegment({
    required this.label,
    required this.icon,
    required this.color,
    required this.probability,
    this.xpReward,
    this.coinReward,
    this.specialReward,
  });
}

/// Default wheel segments
class DefaultWheelSegments {
  static final List<WheelSegment> standard = [
    WheelSegment(
      label: '+25 XP',
      icon: '⚡',
      color: AppColors.primaryOrangeLight,
      probability: 0.30,
      xpReward: 25,
    ),
    WheelSegment(
      label: '+50 XP',
      icon: '🔥',
      color: AppColors.primaryOrange,
      probability: 0.25,
      xpReward: 50,
    ),
    WheelSegment(
      label: '+100 XP',
      icon: '💎',
      color: AppColors.secondaryPurpleLight,
      probability: 0.15,
      xpReward: 100,
    ),
    WheelSegment(
      label: '2x Boost',
      icon: '🚀',
      color: AppColors.info,
      probability: 0.10,
      specialReward: '2x_boost',
    ),
    WheelSegment(
      label: '+20 Coins',
      icon: '🪙',
      color: AppColors.gold,
      probability: 0.10,
      coinReward: 20,
    ),
    WheelSegment(
      label: 'Bronze Box',
      icon: '📦',
      color: AppColors.badgeBronze,
      probability: 0.07,
      specialReward: 'bronze_chest',
    ),
    WheelSegment(
      label: 'Silver Box',
      icon: '🎁',
      color: AppColors.badgeSilver,
      probability: 0.025,
      specialReward: 'silver_chest',
    ),
    WheelSegment(
      label: 'JACKPOT!',
      icon: '👑',
      color: AppColors.goldDark,
      probability: 0.005,
      xpReward: 500,
      coinReward: 100,
    ),
  ];
}

/// Spin wheel screen/dialog
class SpinWheelScreen extends StatefulWidget {
  final bool canSpin;
  final DateTime? nextSpinTime;

  const SpinWheelScreen({
    super.key,
    this.canSpin = true,
    this.nextSpinTime,
  });

  static Future<void> show(BuildContext context, {bool canSpin = true, DateTime? nextSpinTime}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SpinWheelScreen(canSpin: canSpin, nextSpinTime: nextSpinTime),
    );
  }

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> {
  bool _showConfetti = false;
  WheelSegment? _winner;

  void _onWin(WheelSegment segment) {
    setState(() {
      _winner = segment;
      _showConfetti = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: _showConfetti,
      type: _winner?.label == 'JACKPOT!' ? ConfettiType.gold : ConfettiType.celebration,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Text('🎡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lucky Spin',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.secondaryPurple,
                          ),
                        ),
                        Text(
                          widget.canSpin
                              ? 'Spin to win rewards!'
                              : 'Come back tomorrow!',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Wheel
              SpinWheel(
                segments: DefaultWheelSegments.standard,
                canSpin: widget.canSpin && _winner == null,
                onWin: _onWin,
              ),

              const SizedBox(height: 16),

              // Timer if can't spin
              if (!widget.canSpin && widget.nextSpinTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 18, color: AppColors.gray500),
                      const SizedBox(width: 8),
                      Text(
                        'Next spin in: ${_formatDuration(widget.nextSpinTime!.difference(DateTime.now()))}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Now!';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

