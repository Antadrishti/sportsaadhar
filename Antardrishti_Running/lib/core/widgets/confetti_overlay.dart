import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Confetti explosion overlay for celebrations
class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final ConfettiType type;
  final VoidCallback? onComplete;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    required this.child,
    this.isActive = false,
    this.type = ConfettiType.celebration,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles.clear();
    
    final particleCount = widget.type == ConfettiType.epic ? 150 : 80;
    
    for (int i = 0; i < particleCount; i++) {
      _particles.add(ConfettiParticle(
        color: _getRandomColor(),
        x: _random.nextDouble(),
        y: -0.1 - (_random.nextDouble() * 0.3),
        vx: (_random.nextDouble() - 0.5) * 2,
        vy: _random.nextDouble() * 2 + 1,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        size: _random.nextDouble() * 8 + 4,
        shape: ConfettiShape.values[_random.nextInt(ConfettiShape.values.length)],
      ));
    }
    
    _controller.forward(from: 0);
  }

  Color _getRandomColor() {
    final colors = widget.type == ConfettiType.gold
        ? [
            AppColors.gold,
            AppColors.goldLight,
            AppColors.goldDark,
            AppColors.primaryOrange,
            AppColors.white,
          ]
        : [
            AppColors.primaryOrange,
            AppColors.secondaryPurple,
            AppColors.gold,
            AppColors.success,
            AppColors.info,
            const Color(0xFFFF6B6B),
            const Color(0xFF4ECDC4),
            const Color(0xFFFFE66D),
            const Color(0xFF95E1D3),
          ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final x = (particle.x + particle.vx * progress * 0.3) * size.width;
      final y = (particle.y + particle.vy * progress) * size.height;
      final rotation = particle.rotation + particle.rotationSpeed * progress * 360;

      if (y > size.height + 20) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation * pi / 180);

      switch (particle.shape) {
        case ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size),
            paint,
          );
          break;
        case ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
          break;
        case ConfettiShape.rectangle:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 2),
            paint,
          );
          break;
        case ConfettiShape.star:
          _drawStar(canvas, paint, particle.size);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final outerRadius = size / 2;
    final innerRadius = size / 4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;

      if (i == 0) {
        path.moveTo(outerRadius * cos(outerAngle), outerRadius * sin(outerAngle));
      } else {
        path.lineTo(outerRadius * cos(outerAngle), outerRadius * sin(outerAngle));
      }
      path.lineTo(innerRadius * cos(innerAngle), innerRadius * sin(innerAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ConfettiParticle {
  final Color color;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final double size;
  final ConfettiShape shape;

  ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.shape,
  });
}

enum ConfettiShape { square, circle, rectangle, star }

enum ConfettiType { celebration, gold, epic }

/// Controller to trigger confetti from anywhere
class ConfettiController extends ChangeNotifier {
  bool _isActive = false;
  ConfettiType _type = ConfettiType.celebration;

  bool get isActive => _isActive;
  ConfettiType get type => _type;

  void play({ConfettiType type = ConfettiType.celebration}) {
    _type = type;
    _isActive = true;
    notifyListeners();
  }

  void stop() {
    _isActive = false;
    notifyListeners();
  }
}

/// Simple confetti trigger widget
class ConfettiTrigger extends StatefulWidget {
  final Widget child;
  final ConfettiController controller;

  const ConfettiTrigger({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<ConfettiTrigger> createState() => _ConfettiTriggerState();
}

class _ConfettiTriggerState extends State<ConfettiTrigger> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: widget.controller.isActive,
      type: widget.controller.type,
      onComplete: widget.controller.stop,
      child: widget.child,
    );
  }
}

