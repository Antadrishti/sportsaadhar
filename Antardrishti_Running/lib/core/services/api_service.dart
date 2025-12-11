import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../models/leaderboard.dart';
import '../models/achievement.dart';

class ApiService {
  final Dio _dio;
  static const String _userKey = 'logged_in_user';

  ApiService({String? token})
      : _dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            // Increased timeouts for API calls
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        ) {
    debugPrint('ApiService: Using base URL: ${Env.apiBaseUrl}');
    
    // Add interceptor to automatically attach auth token from SharedPreferences
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip if token is already set (e.g., passed via constructor)
        if (options.headers['Authorization'] != null) {
          return handler.next(options);
        }
        
        try {
          final prefs = await SharedPreferences.getInstance();
          final userData = prefs.getString(_userKey);
          if (userData != null) {
            final user = jsonDecode(userData);
            final storedToken = user['token'];
            if (storedToken != null && storedToken.toString().isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $storedToken';
              debugPrint('ApiService: Auth token attached to request');
            }
          }
        } catch (e) {
          debugPrint('ApiService: Error reading token from storage: $e');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('ApiService: 401 Unauthorized - Token may be invalid or expired');
        }
        return handler.next(error);
      },
    ));
  }
  
  Dio get client => _dio;

  // ============ PROGRESS ENDPOINTS ============

  /// Get user's complete progress data
  Future<Map<String, dynamic>> fetchUserProgress(String userId) async {
    try {
      final response = await _dio.get('/progress/$userId');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching user progress: $e');
      rethrow;
    }
  }

  /// Update user's streak on login
  Future<Map<String, dynamic>> updateStreak(String userId) async {
    try {
      final response = await _dio.post('/progress/update-streak', data: {
        'userId': userId,
      });
      return response.data;
    } catch (e) {
      debugPrint('Error updating streak: $e');
      rethrow;
    }
  }

  /// Get all available achievements with unlock status
  Future<List<Achievement>> fetchAchievements(String? userId) async {
    try {
      final endpoint = userId != null ? '/progress/achievements/$userId' : '/progress/achievements';
      final response = await _dio.get(endpoint);
      
      final achievements = (response.data['achievements'] as List)
          .map((json) => Achievement.fromJson(json))
          .toList();
      
      return achievements;
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      rethrow;
    }
  }

  /// Unlock an achievement (usually auto-triggered)
  Future<Map<String, dynamic>> unlockAchievement(String userId, String achievementId) async {
    try {
      final response = await _dio.post('/progress/unlock-achievement', data: {
        'userId': userId,
        'achievementId': achievementId,
      });
      return response.data;
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
      rethrow;
    }
  }

  /// Get test history (best + latest 5 attempts)
  Future<Map<String, dynamic>> fetchTestHistory(String userId, String testId) async {
    try {
      final response = await _dio.get('/progress/test-history/$userId/$testId');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching test history: $e');
      rethrow;
    }
  }

  /// Get category scores
  Future<Map<String, dynamic>> fetchCategoryScores(String userId) async {
    try {
      final response = await _dio.get('/progress/category-scores/$userId');
      return response.data;
    } catch (e) {
      debugPrint('Error fetching category scores: $e');
      rethrow;
    }
  }

  // ============ LEADERBOARD ENDPOINTS ============

  /// Get global leaderboard (top 50 + user position)
  Future<LeaderboardData> fetchGlobalLeaderboard({String? userId}) async {
    try {
      final response = await _dio.get('/leaderboard/global', queryParameters: {
        if (userId != null) 'userId': userId,
      });
      return LeaderboardData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching global leaderboard: $e');
      rethrow;
    }
  }

  /// Get regional leaderboard (top 50 + user position)
  Future<LeaderboardData> fetchRegionalLeaderboard(String state, {String? userId}) async {
    try {
      final response = await _dio.get('/leaderboard/regional/$state', queryParameters: {
        if (userId != null) 'userId': userId,
      });
      return LeaderboardData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching regional leaderboard: $e');
      rethrow;
    }
  }

  /// Get age group leaderboard (top 50 + user position)
  Future<LeaderboardData> fetchAgeGroupLeaderboard(String ageGroup, {String? userId}) async {
    try {
      final response = await _dio.get('/leaderboard/age-group/$ageGroup', queryParameters: {
        if (userId != null) 'userId': userId,
      });
      return LeaderboardData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching age group leaderboard: $e');
      rethrow;
    }
  }

  /// Get gender leaderboard (top 50 + user position)
  Future<LeaderboardData> fetchGenderLeaderboard(String gender, {String? userId}) async {
    try {
      final response = await _dio.get('/leaderboard/gender/$gender', queryParameters: {
        if (userId != null) 'userId': userId,
      });
      return LeaderboardData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching gender leaderboard: $e');
      rethrow;
    }
  }

  /// Get test-specific leaderboard (top 50 + user position)
  Future<LeaderboardData> fetchTestLeaderboard(String testId, {String? userId}) async {
    try {
      final response = await _dio.get('/leaderboard/test/$testId', queryParameters: {
        if (userId != null) 'userId': userId,
      });
      return LeaderboardData.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching test leaderboard: $e');
      rethrow;
    }
  }

  /// Get user's ranks in all categories
  Future<UserRanks> fetchUserRanks(String userId) async {
    try {
      final response = await _dio.get('/leaderboard/user-rank/$userId');
      return UserRanks.fromJson(response.data['ranks']);
    } catch (e) {
      debugPrint('Error fetching user ranks: $e');
      rethrow;
    }
  }
}
