import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'confetti_overlay.dart';

/// Treasure chest with opening animation
class TreasureChest extends StatefulWidget {
  final ChestType type;
  final bool isOpened;
  final VoidCallback? onTap;

  const TreasureChest({
    super.key,
    required this.type,
    this.isOpened = false,
    this.onTap,
  });

  @override
  State<TreasureChest> createState() => _TreasureChestState();
}

class _TreasureChestState extends State<TreasureChest>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.isOpened) {
          _shake();
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        }
      },
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          return Transform.rotate(
            angle: sin(_shakeController.value * pi * 4) * 0.05,
            child: child,
          );
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: widget.type.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.type.glowColor.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.isOpened ? '✨' : widget.type.icon,
                style: TextStyle(fontSize: widget.isOpened ? 32 : 40),
              ),
              if (!widget.isOpened)
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.type.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: widget.type.glowColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chest opening screen with animation
class ChestOpeningScreen extends StatefulWidget {
  final ChestType type;
  final VoidCallback onClose;

  const ChestOpeningScreen({
    super.key,
    required this.type,
    required this.onClose,
  });

  static Future<ChestReward?> show(BuildContext context, ChestType type) async {
    return await showDialog<ChestReward>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => ChestOpeningScreen(
        type: type,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<ChestOpeningScreen> createState() => _ChestOpeningScreenState();
}

class _ChestOpeningScreenState extends State<ChestOpeningScreen>
    with TickerProviderStateMixin {
  late AnimationController _openController;
  late AnimationController _revealController;

  ChestReward? _reward;
  bool _isOpening = false;
  bool _showReward = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _openChest() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);
    HapticFeedback.heavyImpact();

    // Generate reward
    _reward = _generateReward();

    // Play opening animation
    await _openController.forward();
    
    HapticFeedback.heavyImpact();
    setState(() {
      _showReward = true;
      _showConfetti = true;
    });

    await _revealController.forward();
  }

  ChestReward _generateReward() {
    final random = Random();
    
    switch (widget.type) {
      case ChestType.bronze:
        return ChestReward(
          xp: 25 + random.nextInt(26), // 25-50
          coins: 5 + random.nextInt(11), // 5-15
          item: random.nextDouble() < 0.3 ? _getRandomItem(Rarity.common) : null,
        );
      case ChestType.silver:
        return ChestReward(
          xp: 50 + random.nextInt(51), // 50-100
          coins: 15 + random.nextInt(21), // 15-35
          item: random.nextDouble() < 0.5 ? _getRandomItem(Rarity.rare) : null,
        );
      case ChestType.gold:
        return ChestReward(
          xp: 100 + random.nextInt(151), // 100-250
          coins: 30 + random.nextInt(41), // 30-70
          item: _getRandomItem(Rarity.epic),
        );
      case ChestType.legendary:
        return ChestReward(
          xp: 250 + random.nextInt(251), // 250-500
          coins: 75 + random.nextInt(76), // 75-150
          item: _getRandomItem(Rarity.legendary),
        );
    }
  }

  ChestItem? _getRandomItem(Rarity rarity) {
    final items = {
      Rarity.common: [
        const ChestItem('Bronze Frame', '🖼️', Rarity.common),
        const ChestItem('Basic Badge', '🏅', Rarity.common),
      ],
      Rarity.rare: [
        const ChestItem('Silver Frame', '🖼️', Rarity.rare),
        const ChestItem('Star Badge', '⭐', Rarity.rare),
      ],
      Rarity.epic: [
        const ChestItem('Gold Frame', '🖼️', Rarity.epic),
        const ChestItem('Fire Badge', '🔥', Rarity.epic),
        const ChestItem('Champion Title', '👑', Rarity.epic),
      ],
      Rarity.legendary: [
        const ChestItem('Diamond Frame', '💎', Rarity.legendary),
        const ChestItem('Legend Badge', '🌟', Rarity.legendary),
        const ChestItem('Legend Title', '👑', Rarity.legendary),
      ],
    };

    final pool = items[rarity] ?? [];
    if (pool.isEmpty) return null;
    return pool[Random().nextInt(pool.length)];
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      isActive: _showConfetti,
      type: widget.type == ChestType.legendary || widget.type == ChestType.gold
          ? ConfettiType.gold
          : ConfettiType.celebration,
      child: Dialog(
        backgroundColor: Colors.transparent,
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
              Text(
                '${widget.type.label} Chest',
                style: AppTypography.titleLarge.copyWith(
                  color: widget.type.glowColor,
                ),
              ),

              const SizedBox(height: 32),

              // Chest
              if (!_showReward)
                GestureDetector(
                  onTap: _openChest,
                  child: AnimatedBuilder(
                    animation: _openController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + (_openController.value * 0.2),
                        child: Opacity(
                          opacity: 1 - _openController.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: widget.type.gradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: widget.type.glowColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.type.icon,
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 800.ms),
                  ),
                ),

              // Reward reveal
              if (_showReward && _reward != null) ...[
                // XP & Coins
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RewardBubble(
                      icon: '⚡',
                      value: '+${_reward!.xp}',
                      label: 'XP',
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 20),
                    _RewardBubble(
                      icon: '🪙',
                      value: '+${_reward!.coins}',
                      label: 'Coins',
                      color: AppColors.gold,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.5, 0.5)),

                // Item
                if (_reward!.item != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: _reward!.item!.rarity.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _reward!.item!.rarity.color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _reward!.item!.icon,
                          style: const TextStyle(fontSize: 48),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _reward!.item!.name,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _reward!.item!.rarity.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
                ],
              ],

              const SizedBox(height: 32),

              // Buttons
              if (!_isOpening)
                Text(
                  'Tap chest to open!',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.gray500,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 600.ms)
              else if (_showReward)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.type.glowColor,
                    ),
                    child: const Text('Awesome! 🎉'),
                  ),
                ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBubble extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;

  const _RewardBubble({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chest types
enum ChestType {
  bronze('Bronze', '📦', AppColors.badgeBronze),
  silver('Silver', '🎁', AppColors.badgeSilver),
  gold('Gold', '🎁', AppColors.gold),
  legendary('Legendary', '👑', AppColors.achievementSpecial);

  final String label;
  final String icon;
  final Color glowColor;

  const ChestType(this.label, this.icon, this.glowColor);

  LinearGradient get gradient {
    switch (this) {
      case ChestType.bronze:
        return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFA8601A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ChestType.silver:
        return const LinearGradient(
          colors: [Color(0xFFC0C0C0), Color(0xFF8A8A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ChestType.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ChestType.legendary:
        return const LinearGradient(
          colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

/// Reward from chest
class ChestReward {
  final int xp;
  final int coins;
  final ChestItem? item;

  const ChestReward({
    required this.xp,
    required this.coins,
    this.item,
  });
}

/// Item from chest
class ChestItem {
  final String name;
  final String icon;
  final Rarity rarity;

  const ChestItem(this.name, this.icon, this.rarity);
}

enum Rarity {
  common('Common', AppColors.gray500),
  rare('Rare', AppColors.info),
  epic('Epic', AppColors.secondaryPurple),
  legendary('Legendary', AppColors.gold);

  final String label;
  final Color color;

  const Rarity(this.label, this.color);

  LinearGradient get gradient {
    switch (this) {
      case Rarity.common:
        return const LinearGradient(colors: [Color(0xFF757575), Color(0xFF616161)]);
      case Rarity.rare:
        return const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF1976D2)]);
      case Rarity.epic:
        return const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]);
      case Rarity.legendary:
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]);
    }
  }
}

