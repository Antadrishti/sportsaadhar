import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/test_result_model.dart';
import 'api_service.dart';

class TestResultsService {
  /// Save a test result to the backend (only if online)
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
      debugPrint('📴 Offline mode: Test result displayed (not stored, not saved to backend)');
      
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
        },
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/test-results'), // Assuming endpoint
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
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
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Handle response mapping if needed
        return {
          'testResult': TestResultModel(
            testName: testName,
            testType: testType,
            distance: distance,
            timeTaken: timeTaken,
            speed: speed,
            date: DateTime.now(),
            // ... map other fields or parse from response
          ),
          'gamification': data['gamification'] ?? {'isOffline': false},
        };
      } else {
        throw Exception('Failed to save result: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving result: $e');
      // Fallback to offline return like above if needed, or rethrow
      rethrow;
    }
  }
}
