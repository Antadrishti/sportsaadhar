import 'package:flutter/foundation.dart';
import '../models/psychometric_test.dart';
import 'api_service.dart';

/// Service for psychometric test operations
class PsychometricService {
  final ApiService _apiService;

  PsychometricService(this._apiService);

  /// Submit psychometric test answers
  Future<Map<String, dynamic>> submitTest(List<PsychometricAnswer> answers) async {
    try {
      final response = await _apiService.client.post(
        '/psychometric/submit',
        data: {
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );

      if (response.data['success'] == true) {
        final result = PsychometricResult.fromJson(response.data['test']);
        
        return {
          'success': true,
          'result': result,
          'xpEarned': response.data['xpEarned'] ?? 0,
          'levelUp': response.data['levelUp'],
          'unlockedAchievements': response.data['unlockedAchievements'] ?? [],
        };
      }

      throw Exception('Failed to submit psychometric test');
    } catch (e) {
      debugPrint('Error submitting psychometric test: $e');
      rethrow;
    }
  }

  /// Get user's psychometric test results
  Future<PsychometricResult?> getResults(String userId) async {
    try {
      final response = await _apiService.client.get('/psychometric/$userId');

      if (response.data['success'] == true) {
        if (response.data['completed'] == true && response.data['test'] != null) {
          return PsychometricResult.fromJson(response.data['test']);
        }
        return null;
      }

      throw Exception('Failed to fetch psychometric results');
    } catch (e) {
      debugPrint('Error fetching psychometric results: $e');
      rethrow;
    }
  }

  /// Get detailed answers for a test (for review)
  Future<Map<String, dynamic>?> getTestAnswers(String testId) async {
    try {
      final response = await _apiService.client.get('/psychometric/answers/$testId');

      if (response.data['success'] == true) {
        return response.data['test'];
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching test answers: $e');
      rethrow;
    }
  }
}


