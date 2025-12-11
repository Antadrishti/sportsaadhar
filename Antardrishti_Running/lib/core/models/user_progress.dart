import 'dart:math' as math;

/// User progress and gamification data model
class UserProgress {
  final int currentXP;
  final int currentLevel;
  final String levelTitle;
  final int streak;
  final int longestStreak;
  final List<bool> weekStreak; // 7 bools for Mon-Sun
  final int testsCompleted;
  final int totalTests;
  final bool psychometricCompleted;
  final int? physicalScore;
  final int? mentalScore;
  final int? overallScore;
  final int? rank;
  final int? regionalRank;
  final int? ageGroupRank;
  final int? genderRank;
  final List<String> unlockedAchievements;
  final CategoryScores? categoryScores;
  final List<TestProgress> testProgress;

  const UserProgress({
    this.currentXP = 0,
    this.currentLevel = 1,
    this.levelTitle = 'Rookie',
    this.streak = 0,
    this.longestStreak = 0,
    this.weekStreak = const [false, false, false, false, false, false, false],
    this.testsCompleted = 0,
    this.totalTests = 10,
    this.psychometricCompleted = false,
    this.physicalScore,
    this.mentalScore,
    this.overallScore,
    this.rank,
    this.regionalRank,
    this.ageGroupRank,
    this.genderRank,
    this.unlockedAchievements = const [],
    this.categoryScores,
    this.testProgress = const [],
  });

  /// Calculate XP needed for current level
  int get xpForCurrentLevel => LevelSystem.getXPForLevel(currentLevel);
  
  /// Calculate XP needed for next level
  int get xpForNextLevel => LevelSystem.getXPForLevel(currentLevel + 1);
  
  /// Progress percentage to next level
  double get levelProgress {
    final xpInLevel = currentXP - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    // At max level, xpNeeded is 0; return 1.0 to indicate fully complete
    if (xpNeeded <= 0) return 1.0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }
  
  /// Test completion progress (0.0 to 1.0)
  double get testCompletionProgress => totalTests > 0 ? testsCompleted / totalTests : 0.0;
  
  /// Overall journey progress (0.0 to 1.0)
  double get journeyProgress {
    // Phase 1 (tests): 60% of total
    // Phase 2 (psychometric): 30% of total
    // Phase 3 (card): 10% of total
    double progress = testCompletionProgress * 0.6;
    if (psychometricCompleted) progress += 0.3;
    if (overallScore != null) progress += 0.1;
    return progress;
  }
  
  /// Current phase in the journey
  int get currentPhase {
    if (testsCompleted < totalTests) return 1;
    if (!psychometricCompleted) return 2;
    if (overallScore == null) return 3;
    return 3; // Completed
  }
  
  /// Whether all phases are complete
  bool get isJourneyComplete => 
      testsCompleted >= totalTests && 
      psychometricCompleted && 
      overallScore != null;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      currentXP: json['currentXP'] ?? 0,
      currentLevel: json['currentLevel'] ?? 1,
      levelTitle: json['levelTitle'] ?? 'Rookie',
      streak: json['streak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      weekStreak: (json['weekStreak'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [false, false, false, false, false, false, false],
      testsCompleted: json['testsCompleted'] ?? 0,
      totalTests: json['totalTests'] ?? 10,
      psychometricCompleted: json['psychometricCompleted'] ?? false,
      physicalScore: json['physicalScore'],
      mentalScore: json['mentalScore'],
      overallScore: json['overallScore'],
      rank: json['rank'],
      regionalRank: json['regionalRank'],
      ageGroupRank: json['ageGroupRank'],
      genderRank: json['genderRank'],
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      categoryScores: json['categoryScores'] != null
          ? CategoryScores.fromJson(json['categoryScores'] as Map<String, dynamic>)
          : null,
      testProgress: (json['testProgress'] as List<dynamic>?)
              ?.map((e) => TestProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'currentXP': currentXP,
        'currentLevel': currentLevel,
        'levelTitle': levelTitle,
        'streak': streak,
        'longestStreak': longestStreak,
        'weekStreak': weekStreak,
        'testsCompleted': testsCompleted,
        'totalTests': totalTests,
        'psychometricCompleted': psychometricCompleted,
        'physicalScore': physicalScore,
        'mentalScore': mentalScore,
        'overallScore': overallScore,
        'rank': rank,
        'regionalRank': regionalRank,
        'ageGroupRank': ageGroupRank,
        'genderRank': genderRank,
        'unlockedAchievements': unlockedAchievements,
        if (categoryScores != null) 'categoryScores': categoryScores!.toJson(),
        'testProgress': testProgress.map((e) => e.toJson()).toList(),
      };

  UserProgress copyWith({
    int? currentXP,
    int? currentLevel,
    String? levelTitle,
    int? streak,
    int? longestStreak,
    List<bool>? weekStreak,
    int? testsCompleted,
    int? totalTests,
    bool? psychometricCompleted,
    int? physicalScore,
    int? mentalScore,
    int? overallScore,
    int? rank,
    int? regionalRank,
    int? ageGroupRank,
    int? genderRank,
    List<String>? unlockedAchievements,
    CategoryScores? categoryScores,
    List<TestProgress>? testProgress,
  }) {
    return UserProgress(
      currentXP: currentXP ?? this.currentXP,
      currentLevel: currentLevel ?? this.currentLevel,
      levelTitle: levelTitle ?? this.levelTitle,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      weekStreak: weekStreak ?? this.weekStreak,
      testsCompleted: testsCompleted ?? this.testsCompleted,
      totalTests: totalTests ?? this.totalTests,
      psychometricCompleted: psychometricCompleted ?? this.psychometricCompleted,
      physicalScore: physicalScore ?? this.physicalScore,
      mentalScore: mentalScore ?? this.mentalScore,
      overallScore: overallScore ?? this.overallScore,
      rank: rank ?? this.rank,
      regionalRank: regionalRank ?? this.regionalRank,
      ageGroupRank: ageGroupRank ?? this.ageGroupRank,
      genderRank: genderRank ?? this.genderRank,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      categoryScores: categoryScores ?? this.categoryScores,
      testProgress: testProgress ?? this.testProgress,
    );
  }
}

/// Category scores model (5 categories for physical fitness)
class CategoryScores {
  final int strength;
  final int endurance;
  final int flexibility;
  final int agility;
  final int speed;

  const CategoryScores({
    this.strength = 0,
    this.endurance = 0,
    this.flexibility = 0,
    this.agility = 0,
    this.speed = 0,
  });

  factory CategoryScores.fromJson(Map<String, dynamic> json) {
    // Helper to parse number safely (handles both int and double)
    int parseScore(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    return CategoryScores(
      strength: parseScore(json['strength']),
      endurance: parseScore(json['endurance']),
      flexibility: parseScore(json['flexibility']),
      agility: parseScore(json['agility']),
      speed: parseScore(json['speed']),
    );
  }

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'endurance': endurance,
        'flexibility': flexibility,
        'agility': agility,
        'speed': speed,
      };

  double get average => (strength + endurance + flexibility + agility + speed) / 5;
}

/// Test progress model (best + latest 5 attempts)
class TestProgress {
  final String testId;
  final String testName;
  final double? bestScore;
  final String? bestRating;
  final int? bestPercentile;
  final int attempts;
  final DateTime? lastAttemptDate;
  final List<TestAttempt> recentAttempts;

  const TestProgress({
    required this.testId,
    required this.testName,
    this.bestScore,
    this.bestRating,
    this.bestPercentile,
    this.attempts = 0,
    this.lastAttemptDate,
    this.recentAttempts = const [],
  });

  factory TestProgress.fromJson(Map<String, dynamic> json) {
    // Parse bestPercentile safely (handles both int and double)
    int? parseBestPercentile(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return null;
    }
    
    return TestProgress(
      testId: json['testId'] as String? ?? '',
      testName: json['testName'] as String? ?? 'Unknown Test',
      bestScore: json['bestScore'] != null
          ? (json['bestScore'] is int
              ? (json['bestScore'] as int).toDouble()
              : json['bestScore'] as double)
          : null,
      bestRating: json['bestRating'] as String?,
      bestPercentile: parseBestPercentile(json['bestPercentile']),
      attempts: json['attempts'] as int? ?? 0,
      lastAttemptDate: json['lastAttemptDate'] != null
          ? DateTime.tryParse(json['lastAttemptDate'] as String)
          : null,
      recentAttempts: (json['recentAttempts'] as List<dynamic>?)
              ?.map((e) => TestAttempt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'testName': testName,
        if (bestScore != null) 'bestScore': bestScore,
        if (bestRating != null) 'bestRating': bestRating,
        if (bestPercentile != null) 'bestPercentile': bestPercentile,
        'attempts': attempts,
        if (lastAttemptDate != null) 'lastAttemptDate': lastAttemptDate!.toIso8601String(),
        'recentAttempts': recentAttempts.map((e) => e.toJson()).toList(),
      };
}

/// Individual test attempt
class TestAttempt {
  final double score;
  final String rating;
  final DateTime date;
  final int xpEarned;

  const TestAttempt({
    required this.score,
    required this.rating,
    required this.date,
    this.xpEarned = 0,
  });

  factory TestAttempt.fromJson(Map<String, dynamic> json) {
    return TestAttempt(
      score: (json['score'] is int)
          ? (json['score'] as int).toDouble()
          : (json['score'] as double? ?? 0.0),
      rating: json['rating'] as String? ?? 'bronze',
      date: DateTime.parse(json['date'] as String),
      xpEarned: json['xpEarned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'rating': rating,
        'date': date.toIso8601String(),
        'xpEarned': xpEarned,
      };
}

/// Level system configuration with UNLIMITED LEVELS
class LevelSystem {
  static const Map<int, LevelData> levels = {
    1: LevelData(title: 'Rookie', xpRequired: 0, badge: '🥉'),
    2: LevelData(title: 'Beginner', xpRequired: 200, badge: '🥉'),
    3: LevelData(title: 'Amateur', xpRequired: 500, badge: '🥉'),
    4: LevelData(title: 'Rising Star', xpRequired: 1000, badge: '🥈'),
    5: LevelData(title: 'Competitor', xpRequired: 2000, badge: '🥈'),
    6: LevelData(title: 'Athlete', xpRequired: 3500, badge: '🥈'),
    7: LevelData(title: 'Pro Athlete', xpRequired: 5500, badge: '🥇'),
    8: LevelData(title: 'Elite', xpRequired: 8000, badge: '🥇'),
    9: LevelData(title: 'Champion', xpRequired: 12000, badge: '🏆'),
    10: LevelData(title: 'Legend', xpRequired: 20000, badge: '👑'),
  };

  /// Get XP required for a level (with UNLIMITED levels)
  static int getXPForLevel(int level) {
    if (level <= 1) return 0;
    if (level <= 10) return levels[level]?.xpRequired ?? 0;
    
    // For level 11+, use exponential scaling: xpForLevel(n) = 20000 * 1.5^(n-10)
    final baseXP = levels[10]!.xpRequired; // 20000
    final multiplier = math.pow(1.5, level - 10);
    return (baseXP * multiplier).floor();
  }

  /// Get level title (with UNLIMITED levels)
  static String getTitleForLevel(int level) {
    if (level <= 10) {
      return levels[level]?.title ?? 'Rookie';
    }
    
    // For levels 11+, generate titles
    if (level <= 20) return 'Master Lv.$level';
    if (level <= 50) return 'Grand Master Lv.$level';
    if (level <= 100) return 'Legend Lv.$level';
    return 'Immortal Lv.$level';
  }

  /// Get badge for level
  static String getBadgeForLevel(int level) {
    if (level <= 10) {
      return levels[level]?.badge ?? '🥉';
    }
    
    // For levels 11+
    if (level <= 20) return '🥇';
    if (level <= 50) return '🏆';
    if (level <= 100) return '👑';
    return '💎';
  }

  /// Calculate level from total XP (with UNLIMITED levels)
  static int getLevelForXP(int xp) {
    // Check levels 1-10 first
    for (int i = 10; i >= 1; i--) {
      if (xp >= levels[i]!.xpRequired) {
        // If we're at level 10 threshold, check if we've exceeded it
        if (i == 10 && xp > levels[10]!.xpRequired) {
          // Calculate level beyond 10
          final excessXP = xp - levels[10]!.xpRequired;
          final baseXP = levels[10]!.xpRequired;
          
          // Solve for n in: excessXP >= baseXP * (1.5^n - 1)
          final additionalLevels = (math.log(excessXP / baseXP + 1) / math.log(1.5)).floor();
          return 10 + additionalLevels;
        }
        return i;
      }
    }
    return 1;
  }
}


class LevelData {
  final String title;
  final int xpRequired;
  final String badge;

  const LevelData({
    required this.title,
    required this.xpRequired,
    required this.badge,
  });
}

/// XP rewards configuration (CONSERVATIVE SYSTEM)
class XPRewards {
  // Base test completion XP
  static const int baseTest = 30;
  
  // Rating bonuses
  static const int bronze = 0;
  static const int silver = 20;
  static const int gold = 50;
  static const int platinum = 100;
  
  // Improvement bonus
  static const int personalBest = 20;
  
  // Streak rewards (LOW)
  static const int dailyLogin = 5;
  static const int weekStreak = 50;
  static const int twoWeekStreak = 50;
  static const int monthStreak = 200;
  
  // Achievement XP (varies by rarity)
  static const int commonAchievement = 30;
  static const int rareAchievement = 50;
  static const int epicAchievement = 100;
  static const int legendaryAchievement = 200;
}

/// Daily challenge model
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final ChallengeType type;
  final bool isCompleted;
  final DateTime expiresAt;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    this.isCompleted = false,
    required this.expiresAt,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      xpReward: json['xpReward'],
      type: ChallengeType.values[json['type']],
      isCompleted: json['isCompleted'] ?? false,
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'xpReward': xpReward,
        'type': type.index,
        'isCompleted': isCompleted,
        'expiresAt': expiresAt.toIso8601String(),
      };
}

enum ChallengeType {
  quick,
  test,
  streak,
  social,
}

