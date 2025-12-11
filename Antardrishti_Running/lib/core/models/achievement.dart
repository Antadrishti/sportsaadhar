/// Achievement model matching backend Achievement schema
class Achievement {
  final String achievementId;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final bool isHidden;

  const Achievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.xpReward,
    this.isUnlocked = false,
    this.unlockedAt,
    this.isHidden = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      achievementId: json['achievementId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String? ?? '',
      category: _parseCategoryFromString(json['category'] as String?),
      rarity: _parseRarityFromString(json['rarity'] as String?),
      xpReward: json['xpReward'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.name,
      'rarity': rarity.name,
      'xpReward': xpReward,
      'isUnlocked': isUnlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
      'isHidden': isHidden,
    };
  }

  static AchievementCategory _parseCategoryFromString(String? category) {
    switch (category?.toLowerCase()) {
      case 'physical':
        return AchievementCategory.physical;
      case 'dedication':
        return AchievementCategory.dedication;
      case 'special':
        return AchievementCategory.special;
      case 'general':
      default:
        return AchievementCategory.general;
    }
  }

  static AchievementRarity _parseRarityFromString(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'legendary':
        return AchievementRarity.legendary;
      case 'epic':
        return AchievementRarity.epic;
      case 'rare':
        return AchievementRarity.rare;
      case 'common':
      default:
        return AchievementRarity.common;
    }
  }

  Achievement copyWith({
    String? achievementId,
    String? title,
    String? description,
    String? icon,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? xpReward,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? isHidden,
  }) {
    return Achievement(
      achievementId: achievementId ?? this.achievementId,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      xpReward: xpReward ?? this.xpReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}

/// Achievement category enum (matching backend)
enum AchievementCategory {
  physical,
  dedication,
  special,
  general,
}

/// Achievement rarity enum (matching backend)
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Unlocked achievement data from user's profile
class UnlockedAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final int xpEarned;

  const UnlockedAchievement({
    required this.achievementId,
    required this.unlockedAt,
    required this.xpEarned,
  });

  factory UnlockedAchievement.fromJson(Map<String, dynamic> json) {
    return UnlockedAchievement(
      achievementId: json['achievementId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      xpEarned: json['xpEarned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'xpEarned': xpEarned,
    };
  }
}


