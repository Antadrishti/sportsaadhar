import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

/// Primary animated button with glow effect
class AnimatedPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool iconAtEnd;
  final double? width;
  final double height;
  final bool useGradient;

  const AnimatedPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconAtEnd = false,
    this.width,
    this.height = 56,
    this.useGradient = false,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: isDisabled 
                    ? null 
                    : widget.useGradient 
                        ? AppGradients.primaryOrange 
                        : null,
                color: isDisabled 
                    ? AppColors.gray300 
                    : widget.useGradient 
                        ? null 
                        : AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primaryOrange
                              .withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: AppColors.primaryOrange
                              .withOpacity(0.2 * _glowAnimation.value),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null && !widget.iconAtEnd) ...[
                            Icon(
                              widget.icon,
                              color: isDisabled 
                                  ? AppColors.gray500 
                                  : AppColors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: AppTypography.button.copyWith(
                              color: isDisabled 
                                  ? AppColors.gray500 
                                  : AppColors.white,
                            ),
                          ),
                          if (widget.icon != null && widget.iconAtEnd) ...[
                            const SizedBox(width: 8),
                            Icon(
                              widget.icon,
                              color: isDisabled 
                                  ? AppColors.gray500 
                                  : AppColors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Secondary outlined button
class AnimatedSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;
  final double height;

  const AnimatedSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width,
    this.height = 56,
  });

  @override
  State<AnimatedSecondaryButton> createState() => _AnimatedSecondaryButtonState();
}

class _AnimatedSecondaryButtonState extends State<AnimatedSecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppColors.primaryOrange;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) {
          _controller.forward();
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDisabled ? AppColors.gray300 : buttonColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: buttonColor,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: isDisabled 
                                  ? AppColors.gray400 
                                  : buttonColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: AppTypography.button.copyWith(
                              color: isDisabled 
                                  ? AppColors.gray400 
                                  : buttonColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small icon button with animation
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 44,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = widget.color ?? 
        (isDark ? AppColors.darkTextPrimary : AppColors.secondaryPurple);
    final bgColor = widget.backgroundColor ?? 
        (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant);

    Widget button = GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          _controller.forward();
          HapticFeedback.selectionClick();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(widget.size / 4),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: widget.onPressed == null 
                      ? AppColors.gray400 
                      : iconColor,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Floating action button with animation
class AnimatedFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool extended;

  const AnimatedFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.extended = false,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          _controller.forward();
          HapticFeedback.mediumImpact();
        }
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.extended ? 20 : 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryOrange,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.glowOrange,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: AppColors.white,
                    size: 24,
                  ),
                  if (widget.extended && widget.label != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      widget.label!,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

