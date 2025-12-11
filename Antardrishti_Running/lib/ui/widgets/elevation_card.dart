import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ElevationCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final GestureTapCallback? onTap;

  const ElevationCard({super.key, required this.child, this.padding, this.margin, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    final ink = onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: card,
          );

    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      child: ink,
    ).animate().fade(duration: 250.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), curve: Curves.easeOut);
  }
}
