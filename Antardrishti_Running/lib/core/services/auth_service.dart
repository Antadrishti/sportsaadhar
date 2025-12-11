import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'image_storage_service.dart';

class AuthService {
  static const _userKey = 'logged_in_user';
  final ImageStorageService _imageStorageService = ImageStorageService();

  /// Download and save profile image locally for face verification
  Future<void> _downloadProfileImage(User user) async {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      try {
        debugPrint('AuthService: Downloading profile image for ${user.aadhaarNumber}');
        await _imageStorageService.downloadAndSaveImage(
          user.profileImageUrl!,
          user.aadhaarNumber,
        );
        debugPrint('AuthService: Profile image downloaded and saved locally');
      } catch (e) {
        debugPrint('AuthService: Failed to download profile image: $e');
        // Don't throw - profile image download is not critical for auth
      }
    }
  }

  /// Generate a mock request ID locally (no network call needed for mock auth)
  String _generateMockRequestId(String aadhaarNumber) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex}_$aadhaarNumber';
  }

  /// Send OTP for Aadhaar verification (mock - instant, no network call)
  /// Returns requestId for verification
  Future<String> sendOTP(String aadhaarNumber) async {
    // Mock implementation - generate request ID locally for instant response
    // No network call needed since OTP is always "123456"
    debugPrint('Mock OTP sent for Aadhaar: ${aadhaarNumber.substring(0, 4)}XXXXXXXX');
    return _generateMockRequestId(aadhaarNumber);
  }

  /// Verify OTP and return user if exists, or indication that registration is needed
  /// Returns a map with 'user' (if exists) and 'requiresRegistration' flag
  Future<Map<String, dynamic>> verifyOTP(
      String requestId, String code, String aadhaarNumber) async {
    
    // Demo mode: work completely offline
    if (Env.demoMode) {
      debugPrint('AuthService: Demo mode - verifying OTP offline');
      
      // Check if OTP is correct (mock OTP is 123456)
      if (code != '123456') {
        throw Exception('Invalid OTP. Please enter 123456');
      }
      
      // Check if user exists locally
      final prefs = await SharedPreferences.getInstance();
      final existingData = prefs.getString(_userKey);
      
      if (existingData != null) {
        // Check if the stored user matches this Aadhaar
        final existingUser = User.fromJson(jsonDecode(existingData));
        if (existingUser.aadhaarNumber == aadhaarNumber) {
          debugPrint('AuthService: Demo mode - existing user found');
          return {
            'user': existingUser,
            'requiresRegistration': false,
          };
        }
      }
      
      // No existing user, need registration
      debugPrint('AuthService: Demo mode - new user, needs registration');
      return {
        'requestId': requestId,
        'aadhaarNumber': aadhaarNumber,
        'requiresRegistration': true,
      };
    }
    
    // Online mode: call backend API
    try {
      final api = ApiService();
      final resp = await api.client.post('/auth/verify-otp', data: {
        'requestId': requestId,
        'code': code,
        'aadhaarNumber': aadhaarNumber,
      });

      final data = resp.data as Map<String, dynamic>;
      final requiresRegistration = data['requiresRegistration'] as bool? ?? false;

      if (!requiresRegistration) {
        // User exists, login successful
        final user = User.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        
        // Download profile image locally for face verification
        await _downloadProfileImage(user);
        
        return {
          'user': user,
          'requiresRegistration': false,
        };
      } else {
        // User doesn't exist, need to complete registration
        return {
          'requestId': data['requestId'] as String,
          'aadhaarNumber': data['aadhaarNumber'] as String,
          'requiresRegistration': true,
        };
      }
    } on DioException catch (e) {
      final msg = _dioErrorToMessage(e);
      throw Exception(msg);
    }
  }

  /// Complete registration after Aadhaar OTP verification
  Future<User> completeRegistration({
    required String name,
    required String aadhaarNumber,
    required String requestId,
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String disability,
    required String phoneNumber,
    String? email,
    File? profileImage,
  }) async {
    
    // Demo mode: save user locally without backend
    if (Env.demoMode) {
      debugPrint('AuthService: Demo mode - completing registration offline');
      
      // Generate a mock user ID and token
      final mockId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
      final mockToken = 'demo_token_$mockId';
      
      final user = User(
        id: mockId,
        name: name,
        aadhaarNumber: aadhaarNumber,
        age: age,
        height: height,
        weight: weight,
        gender: gender,
        address: address,
        city: city,
        state: state,
        pincode: pincode,
        disability: disability,
        phoneNumber: phoneNumber,
        email: email,
        profileImageUrl: null, // Profile image stored locally in demo mode
        token: mockToken,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      // Save profile image locally if provided
      if (profileImage != null) {
        try {
          await _imageStorageService.saveProfileImage(profileImage, aadhaarNumber);
          debugPrint('AuthService: Demo mode - profile image saved locally');
        } catch (e) {
          debugPrint('AuthService: Demo mode - failed to save profile image: $e');
        }
      }
      
      debugPrint('AuthService: Demo mode - registration complete for $name');
      return user;
    }
    
    // Online mode: call backend API
    try {
      final api = ApiService();
      
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'name': name,
        'aadhaarNumber': aadhaarNumber,
        'requestId': requestId,
        'age': age.toString(),
        'height': height.toString(),
        'weight': weight.toString(),
        'gender': gender,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'disability': disability,
        'phoneNumber': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
      });

      // Add image file if provided
      if (profileImage != null) {
        final fileName = profileImage.path.split('/').last;
        formData.files.add(
          MapEntry(
            'profileImage',
            await MultipartFile.fromFile(
              profileImage.path,
              filename: fileName,
            ),
          ),
        );
      }

      final resp = await api.client.post(
        '/auth/complete-registration',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final user = User.fromJson(resp.data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      
      // Download profile image locally for face verification
      // This downloads the Cloudinary URL image to local storage
      await _downloadProfileImage(user);
      
      return user;
    } on DioException catch (e) {
      final msg = _dioErrorToMessage(e);
      throw Exception(msg);
    }
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    return User.fromJson(jsonDecode(data));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Fetches the user profile from the API using the stored JWT token
  /// and updates the locally stored user while preserving the token.
  Future<User> fetchProfileAndUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null) {
      throw Exception('Not logged in');
    }

    final current = User.fromJson(jsonDecode(data));

    // Demo mode: just return the locally stored user
    if (Env.demoMode) {
      debugPrint('AuthService: Demo mode - returning local user profile');
      return current;
    }

    try {
      final api = ApiService(token: current.token);
      final resp = await api.client.get('/profile');

      final json = resp.data as Map<String, dynamic>;
      final updated = User(
        id: (json['id'] ?? json['_id'] ?? current.id) as String,
        name: (json['name'] ?? current.name) as String,
        aadhaarNumber: (json['aadhaarNumber'] ?? current.aadhaarNumber) as String,
        age: (json['age'] ?? current.age) as int,
        height: (json['height'] is int) 
            ? (json['height'] as int).toDouble() 
            : (json['height'] ?? current.height) as double,
        weight: (json['weight'] is int) 
            ? (json['weight'] as int).toDouble() 
            : (json['weight'] ?? current.weight) as double,
        gender: (json['gender'] ?? current.gender) as String,
        address: (json['address'] ?? current.address) as String,
        city: (json['city'] ?? current.city) as String,
        state: (json['state'] ?? current.state) as String,
        pincode: (json['pincode'] ?? current.pincode) as String,
        disability: (json['disability'] ?? current.disability) as String,
        phoneNumber: (json['phoneNumber'] ?? current.phoneNumber) as String,
        email: json['email'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        token: current.token,
      );

      await prefs.setString(_userKey, jsonEncode(updated.toJson()));
      
      // Download profile image if URL changed or exists
      if (updated.profileImageUrl != current.profileImageUrl) {
        await _downloadProfileImage(updated);
      }
      
      return updated;
    } on DioException catch (e) {
      throw Exception(_dioErrorToMessage(e));
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
