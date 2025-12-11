import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Change this to your server URL when deploying
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS simulator
  // static const String baseUrl = 'http://10.12.4.194:3000/api'; // Physical device
  static const String baseUrl = 'http://192.168.239.5:3000/api'; // Physical device
  
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';

  // Get stored token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login or Register
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Store token and user info
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _userIdKey, value: data['user']['id']);
        await _storage.write(key: _usernameKey, value: data['user']['username']);
        return {'success': true, 'message': data['message'], 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Get headers with auth token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'profile': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    int? age,
    String? gender,
    String? address,
    String? region,
    String? pincode,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{};
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;
      if (address != null) body['address'] = address;
      if (region != null) body['region'] = region;
      if (pincode != null) body['pincode'] = pincode;

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Profile updated'};
      } else {
        return {'success': false, 'error': 'Failed to update profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Submit test result
  static Future<Map<String, dynamic>> submitTestResult({
    required String testName,
    required double value,
    required String unit,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/tests/submit'),
        headers: headers,
        body: jsonEncode({
          'testName': testName,
          'value': value,
          'unit': unit,
          'metadata': {'notes': notes ?? ''},
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Test result saved'};
      } else {
        return {'success': false, 'error': 'Failed to save test result'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Get test history
  static Future<Map<String, dynamic>> getTestHistory() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tests/history'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'history': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to fetch history'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  // Get latest test result for a specific test
  static Future<double?> getLatestTestValue(String testName) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tests/latest/$testName'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['value']?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
