import 'package:flutter/foundation.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../models/leaderboard.dart';
import 'api_service.dart';

/// Progress Service - Manages local and remote progress sync
class ProgressService {
  final ApiService _apiService;
  
  // Cached data
  UserProgress? _cachedProgress;
  List<Achievement>? _cachedAchievements;
  Map<String, LeaderboardData>? _cachedLeaderboards;
  DateTime? _lastSync;

  ProgressService(this._apiService);

  /// Sync progress with backend
  Future<UserProgress> syncProgress(String userId) async {
    try {
      final response = await _apiService.fetchUserProgress(userId);
      
      if (response['success'] == true) {
        final progressData = response['progress'];
        
        // Parse weekStreak safely - handle both List and other types
        List<bool> weekStreak = const [false, false, false, false, false, false, false];
        final weekStreakData = progressData['streak']?['weekStreak'];
        if (weekStreakData is List) {
          weekStreak = weekStreakData.map((e) => e == true).toList();
          // Ensure list has exactly 7 elements
          while (weekStreak.length < 7) {
            weekStreak.add(false);
          }
          if (weekStreak.length > 7) {
            weekStreak = weekStreak.sublist(0, 7);
          }
        }
        
        // Parse testProgress safely
        List<TestProgress> testProgress = const [];
        final testProgressData = progressData['testProgress'];
        if (testProgressData is List) {
          testProgress = testProgressData
              .map((e) => TestProgress.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        
        // Parse unlocked achievements - backend returns count as int, not list
        // We'll store the count for now; IDs can be fetched separately if needed
        final achievementsData = progressData['achievements'];
        int unlockedCount = 0;
        if (achievementsData != null) {
          if (achievementsData['unlocked'] is int) {
            unlockedCount = achievementsData['unlocked'] as int;
          } else if (achievementsData['unlocked'] is List) {
            unlockedCount = (achievementsData['unlocked'] as List).length;
          }
        }
        
        // Parse progress data
        _cachedProgress = UserProgress(
          currentXP: progressData['xp']?['currentXP'] ?? 0,
          currentLevel: progressData['xp']?['currentLevel'] ?? 1,
          levelTitle: progressData['xp']?['levelTitle'] ?? 'Rookie',
          streak: progressData['streak']?['currentStreak'] ?? 0,
          longestStreak: progressData['streak']?['longestStreak'] ?? 0,
          weekStreak: weekStreak,
          testsCompleted: progressData['journey']?['testsCompleted'] ?? 0,
          totalTests: progressData['journey']?['totalTests'] ?? 10,
          physicalScore: progressData['physicalScore'],
          rank: progressData['ranks']?['global'],
          regionalRank: progressData['ranks']?['regional'],
          ageGroupRank: progressData['ranks']?['ageGroup'],
          genderRank: progressData['ranks']?['gender'],
          categoryScores: progressData['categoryScores'] != null
              ? CategoryScores.fromJson(progressData['categoryScores'])
              : null,
          testProgress: testProgress,
          // Store empty list for now - count is in unlockedCount
          unlockedAchievements: List.generate(unlockedCount, (i) => 'achievement_$i'),
        );
        
        _lastSync = DateTime.now();
        return _cachedProgress!;
      }
      
      throw Exception('Failed to sync progress');
    } catch (e) {
      debugPrint('Error syncing progress: $e');
      rethrow;
    }
  }

  /// Get cached progress or sync if needed
  Future<UserProgress?> getProgress(String userId, {bool forceSync = false}) async {
    if (forceSync || _cachedProgress == null || _needsSync()) {
      return await syncProgress(userId);
    }
    return _cachedProgress;
  }

  /// Check if sync is needed (every 5 minutes)
  bool _needsSync() {
    if (_lastSync == null) return true;
    return DateTime.now().difference(_lastSync!).inMinutes > 5;
  }

  /// Update streak on login
  Future<Map<String, dynamic>> updateStreak(String userId) async {
    try {
      final response = await _apiService.updateStreak(userId);
      
      if (response['success'] == true) {
        // Update cached progress if available
        if (_cachedProgress != null) {
          _cachedProgress = _cachedProgress!.copyWith(
            streak: response['streak'],
            longestStreak: response['longestStreak'],
          );
        }
        
        return response;
      }
      
      throw Exception('Failed to update streak');
    } catch (e) {
      debugPrint('Error updating streak: $e');
      rethrow;
    }
  }

  /// Load all achievements
  Future<List<Achievement>> loadAchievements(String? userId) async {
    try {
      _cachedAchievements = await _apiService.fetchAchievements(userId);
      return _cachedAchievements!;
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      rethrow;
    }
  }

  /// Get cached achievements
  List<Achievement>? getCachedAchievements() => _cachedAchievements;

  /// Load leaderboard
  Future<LeaderboardData> loadLeaderboard(
    LeaderboardType type, {
    String? userId,
    String? filterValue,
  }) async {
    try {
      LeaderboardData leaderboard;
      
      switch (type) {
        case LeaderboardType.global:
          leaderboard = await _apiService.fetchGlobalLeaderboard(userId: userId);
          break;
        case LeaderboardType.regional:
          if (filterValue == null) throw Exception('State required for regional leaderboard');
          leaderboard = await _apiService.fetchRegionalLeaderboard(filterValue, userId: userId);
          break;
        case LeaderboardType.ageGroup:
          if (filterValue == null) throw Exception('Age group required');
          leaderboard = await _apiService.fetchAgeGroupLeaderboard(filterValue, userId: userId);
          break;
        case LeaderboardType.gender:
          if (filterValue == null) throw Exception('Gender required');
          leaderboard = await _apiService.fetchGenderLeaderboard(filterValue, userId: userId);
          break;
        case LeaderboardType.test:
          if (filterValue == null) throw Exception('Test ID required');
          leaderboard = await _apiService.fetchTestLeaderboard(filterValue, userId: userId);
          break;
      }
      
      // Cache leaderboard
      _cachedLeaderboards ??= {};
      final cacheKey = '${type.name}_${filterValue ?? 'default'}';
      _cachedLeaderboards![cacheKey] = leaderboard;
      
      return leaderboard;
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      rethrow;
    }
  }

  /// Get user ranks
  Future<UserRanks> getUserRanks(String userId) async {
    try {
      return await _apiService.fetchUserRanks(userId);
    } catch (e) {
      debugPrint('Error fetching user ranks: $e');
      rethrow;
    }
  }

  /// Clear cache (call when data changes significantly)
  void clearCache() {
    _cachedProgress = null;
    _cachedAchievements = null;
    _cachedLeaderboards = null;
    _lastSync = null;
  }

  /// Calculate journey progress (0.0 to 1.0)
  double calculateJourneyProgress(int testsCompleted, int totalTests, bool psychometricCompleted) {
    // Phase 1 (tests): 60% of total
    // Phase 2 (psychometric): 30% of total  
    // Phase 3 (card): 10% of total
    double progress = (testsCompleted / totalTests) * 0.6;
    if (psychometricCompleted) progress += 0.3;
    return progress.clamp(0.0, 1.0);
  }
}
