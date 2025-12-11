import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorageService {
  static const String _profileImagesFolder = 'profile_images';

  /// Get the directory for storing profile images
  Future<Directory> _getProfileImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory(path.join(appDir.path, _profileImagesFolder));
    
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    
    return profileDir;
  }

  /// Get the consistent file name for a user's profile image
  /// Uses the user identifier (Aadhaar number) as the unique key
  String _getProfileFileName(String userIdentifier) {
    return 'profile_$userIdentifier.jpg';
  }

  /// Download profile image from URL and save locally
  /// Returns the saved file path
  Future<String?> downloadAndSaveImage(String url, String userIdentifier) async {
    try {
      if (url.isEmpty) {
        debugPrint('ImageStorageService: URL is empty, skipping download');
        return null;
      }

      debugPrint('ImageStorageService: Downloading image from $url');
      
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        debugPrint('ImageStorageService: Downloaded data is empty');
        return null;
      }

      final profileDir = await _getProfileImagesDirectory();
      final fileName = _getProfileFileName(userIdentifier);
      final savedFile = File(path.join(profileDir.path, fileName));

      // Write the downloaded bytes to file
      await savedFile.writeAsBytes(response.data!);

      debugPrint('ImageStorageService: Image saved to ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('ImageStorageService: Failed to download and save image: $e');
      return null;
    }
  }

  /// Get the local file path for a user's profile image
  /// Returns the path if file exists, null otherwise
  Future<String?> getProfileImagePath(String userIdentifier) async {
    try {
      final profileDir = await _getProfileImagesDirectory();
      final fileName = _getProfileFileName(userIdentifier);
      final imageFile = File(path.join(profileDir.path, fileName));

      if (await imageFile.exists()) {
        return imageFile.path;
      }

      return null;
    } catch (e) {
      debugPrint('ImageStorageService: Error getting profile image path: $e');
      return null;
    }
  }

  /// Check if profile image exists locally
  Future<bool> hasProfileImage(String userIdentifier) async {
    final path = await getProfileImagePath(userIdentifier);
    return path != null;
  }

  /// Save image to local storage
  /// Returns the saved file path
  Future<String> saveImage(File imageFile, String fileName) async {
    try {
      final profileDir = await _getProfileImagesDirectory();
      final savedFile = File(path.join(profileDir.path, fileName));
      
      // Copy the file to the profile images directory
      await imageFile.copy(savedFile.path);
      
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  /// Save profile image from a File for a specific user
  /// Uses consistent naming: profile_{userIdentifier}.jpg
  Future<String> saveProfileImage(File imageFile, String userIdentifier) async {
    try {
      final profileDir = await _getProfileImagesDirectory();
      final fileName = _getProfileFileName(userIdentifier);
      final savedFile = File(path.join(profileDir.path, fileName));
      
      // Copy the file to the profile images directory
      await imageFile.copy(savedFile.path);
      
      debugPrint('ImageStorageService: Profile image saved to ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save profile image: $e');
    }
  }

  /// Get saved image file
  Future<File?> getImage(String fileName) async {
    try {
      final profileDir = await _getProfileImagesDirectory();
      final imageFile = File(path.join(profileDir.path, fileName));
      
      if (await imageFile.exists()) {
        return imageFile;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete image from local storage
  Future<bool> deleteImage(String fileName) async {
    try {
      final profileDir = await _getProfileImagesDirectory();
      final imageFile = File(path.join(profileDir.path, fileName));
      
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Delete profile image for a specific user
  Future<bool> deleteProfileImage(String userIdentifier) async {
    final fileName = _getProfileFileName(userIdentifier);
    return deleteImage(fileName);
  }

  /// Generate a unique file name for the profile image
  String generateFileName(String userIdentifier) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'profile_${userIdentifier}_$timestamp.jpg';
  }
}
