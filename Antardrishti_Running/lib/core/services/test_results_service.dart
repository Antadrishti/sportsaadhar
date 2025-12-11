import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/test_result_model.dart';
import 'api_service.dart';

class TestResultsService {
  /// Save a test result to the backend (only if online)
  /// Returns a map with 'testResult' and optional 'gamification' data
  /// If offline, returns a result object in memory (NOT stored locally - just for display)
  /// NOTE: This does NOT store results locally - results are only displayed and optionally saved to backend
  Future<Map<String, dynamic>> saveTestResult({
    required String token,
    required String testName,
    required String testType,
    required double distance,
    required double timeTaken,
    required double speed,
    double? pace,
    double? measuredHeight,
    double? registeredHeight,
    bool? isHeightVerified,
    double? jumpHeight,
    String? jumpType,
    int? repsCount,
    String? exerciseType,
    double? flexibilityAngle,
    String? flexibilityRating,
    int? shuttleRunLaps,
    int? directionChanges,
    double? averageGpsAccuracy,
  }) async {
    // Check connectivity first
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && 
                     !connectivityResults.contains(ConnectivityResult.none);

    if (!isOnline) {
      // Offline mode: Create a result object in memory (NOT stored - just for display)
      debugPrint('📴 Offline mode: Test result displayed (not stored, not saved to backend)');
      
      final localResult = TestResultModel(
        id: null, // No backend ID when offline
        testName: testName,
        testType: testType,
        distance: distance,
        timeTaken: timeTaken,
        speed: speed,
        pace: pace,
        date: DateTime.now(),
        measuredHeight: measuredHeight,
        registeredHeight: registeredHeight,
        isHeightVerified: isHeightVerified,
        jumpHeight: jumpHeight,
        jumpType: jumpType,
        repsCount: repsCount,
        exerciseType: exerciseType,
        flexibilityAngle: flexibilityAngle,
        flexibilityRating: flexibilityRating,
        shuttleRunLaps: shuttleRunLaps,
        directionChanges: directionChanges,
        averageGpsAccuracy: averageGpsAccuracy,
      );
      
      return {
        'testResult': localResult,
        'gamification': <String, dynamic>{
          'isOffline': true,
          'performanceRating': null,
          'percentile': null,
          'xpEarned': 0,
          'xpBreakdown': null,
          'isPersonalBest': false,
          'improvementPercent': null,
          'unlockedAchievements': [],
        },
      };
    }

    // Online mode: Try to save to backend
    try {
      final api = ApiService(token: token);
      final response = await api.client.post(
        '/test-results',
        data: {
          'testName': testName,
          'testType': testType,
          'distance': distance,
          'timeTaken': timeTaken,
          'speed': speed,
          if (pace != null) 'pace': pace,
          if (measuredHeight != null) 'measuredHeight': measuredHeight,
          if (registeredHeight != null) 'registeredHeight': registeredHeight,
          if (isHeightVerified != null) 'isHeightVerified': isHeightVerified,
          if (jumpHeight != null) 'jumpHeight': jumpHeight,
          if (jumpType != null) 'jumpType': jumpType,
          if (repsCount != null) 'repsCount': repsCount,
          if (exerciseType != null) 'exerciseType': exerciseType,
          if (flexibilityAngle != null) 'flexibilityAngle': flexibilityAngle,
          if (flexibilityRating != null) 'flexibilityRating': flexibilityRating,
          if (shuttleRunLaps != null) 'shuttleRunLaps': shuttleRunLaps,
          if (directionChanges != null) 'directionChanges': directionChanges,
          if (averageGpsAccuracy != null) 'averageGpsAccuracy': averageGpsAccuracy,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final testResultData = data['testResult'] as Map<String, dynamic>;
      final testResult = TestResultModel.fromJson(testResultData);
      
      // Extract gamification data if present
      final gamificationData = <String, dynamic>{
        'isOffline': false,
        'performanceRating': testResultData['performanceRating'],
        'percentile': testResultData['percentile'],
        'xpEarned': testResultData['xpEarned'],
        'xpBreakdown': testResultData['xpBreakdown'],
        'isPersonalBest': testResultData['isPersonalBest'] ?? false,
        'improvementPercent': testResultData['improvementPercent'],
        'unlockedAchievements': testResultData['unlockedAchievements'] ?? [],
      };
      
      return {
        'testResult': testResult,
        'gamification': gamificationData,
      };
    } on DioException catch (e) {
      // If network error, fall back to offline mode (display only, no storage)
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('📴 Network error: Falling back to offline mode (display only, not stored)');
        
        final localResult = TestResultModel(
          id: null,
          testName: testName,
          testType: testType,
          distance: distance,
          timeTaken: timeTaken,
          speed: speed,
          pace: pace,
          date: DateTime.now(),
          measuredHeight: measuredHeight,
          registeredHeight: registeredHeight,
          isHeightVerified: isHeightVerified,
          jumpHeight: jumpHeight,
          jumpType: jumpType,
          repsCount: repsCount,
          exerciseType: exerciseType,
          flexibilityAngle: flexibilityAngle,
          flexibilityRating: flexibilityRating,
          shuttleRunLaps: shuttleRunLaps,
          directionChanges: directionChanges,
          averageGpsAccuracy: averageGpsAccuracy,
        );
        
        return {
          'testResult': localResult,
          'gamification': <String, dynamic>{
            'isOffline': true,
            'performanceRating': null,
            'percentile': null,
            'xpEarned': 0,
            'xpBreakdown': null,
            'isPersonalBest': false,
            'improvementPercent': null,
            'unlockedAchievements': [],
          },
        };
      }
      
      // For other errors, still throw
      final msg = _dioErrorToMessage(e);
      throw Exception(msg);
    }
  }

  /// Get all test results for the authenticated user
  /// Returns empty list if offline
  Future<List<TestResultModel>> getUserTestResults({
    required String token,
    String? testName,
    int? limit,
  }) async {
    // Check connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && 
                     !connectivityResults.contains(ConnectivityResult.none);

    if (!isOnline) {
      debugPrint('📴 Offline mode: Cannot fetch test results from backend');
      return [];
    }

    try {
      final api = ApiService(token: token);
      final queryParams = <String, dynamic>{};
      if (testName != null) queryParams['testName'] = testName;
      if (limit != null) queryParams['limit'] = limit;

      final response = await api.client.get(
        '/test-results',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data as Map<String, dynamic>;
      final results = (data['testResults'] as List)
          .map((json) => TestResultModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return results;
    } on DioException catch (e) {
      // If network error, return empty list instead of throwing
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('📴 Network error: Returning empty test results list');
        return [];
      }
      final msg = _dioErrorToMessage(e);
      throw Exception(msg);
    }
  }

  /// Get the latest test result for a specific test
  /// Returns null if offline or not found
  Future<TestResultModel?> getLatestTestResult({
    required String token,
    required String testName,
  }) async {
    // Check connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    final isOnline = connectivityResults.isNotEmpty && 
                     !connectivityResults.contains(ConnectivityResult.none);

    if (!isOnline) {
      debugPrint('📴 Offline mode: Cannot fetch latest test result from backend');
      return null;
    }

    try {
      final api = ApiService(token: token);
      final response = await api.client.get(
        '/test-results/$testName/latest',
      );

      final data = response.data as Map<String, dynamic>;
      final testResult = TestResultModel.fromJson(data['testResult'] as Map<String, dynamic>);
      return testResult;
    } on DioException catch (e) {
      // Return null if no results found (404) or network error
      if (e.response?.statusCode == 404) {
        return null;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('📴 Network error: Returning null for latest test result');
        return null;
      }
      final msg = _dioErrorToMessage(e);
      throw Exception(msg);
    }
  }

  String _dioErrorToMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Network timeout. Please try again.';
    }
    if (e.type == DioExceptionType.badResponse) {
      return 'Request failed: ${e.response?.statusCode ?? ''}';
    }
    return 'Network error. Please try again.';
  }
}

