import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Service for measuring height using MediaPipe pose detection
/// Based on the algorithm: finger-to-foot distance = 100cm reference
class HeightMeasurementService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  /// Measure height from a video file
  /// Returns the average height in centimeters, or null if measurement failed
  Future<HeightMeasurementResult> measureHeightFromVideo(String videoPath) async {
    List<double> validHeights = [];
    List<String> errors = [];

    try {
      // Extract frames from video at regular intervals
      final frames = await _extractFramesFromVideo(videoPath, maxFrames: 30);
      
      if (frames.isEmpty) {
        return HeightMeasurementResult(
          success: false,
          errorMessage: 'Failed to extract frames from video',
        );
      }

      debugPrint('📹 Extracted ${frames.length} frames for height analysis');

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        try {
          final inputImage = InputImage.fromFilePath(frames[i]);
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty) {
            final pose = poses.first;
            final height = _calculateHeightFromPose(pose);
            
            if (height != null) {
              validHeights.add(height);
              debugPrint('✅ Frame $i: Height = ${height.toStringAsFixed(1)} cm');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing frame $i: $e');
          errors.add('Frame $i error: $e');
        }
      }

      // Clean up temporary frame files
      for (final framePath in frames) {
        try {
          await File(framePath).delete();
        } catch (e) {
          debugPrint('Failed to delete temp frame: $e');
        }
      }

      // Calculate average height
      if (validHeights.isEmpty) {
        return HeightMeasurementResult(
          success: false,
          errorMessage: 'No valid height measurements detected. '
              'Make sure your right hand and right foot are clearly visible.',
          detectedFrames: 0,
          totalFrames: frames.length,
        );
      }

      final averageHeight = validHeights.reduce((a, b) => a + b) / validHeights.length;
      
      debugPrint('📊 Final Result: ${averageHeight.toStringAsFixed(1)} cm '
          '(from ${validHeights.length}/${frames.length} valid frames)');

      return HeightMeasurementResult(
        success: true,
        heightInCm: averageHeight,
        detectedFrames: validHeights.length,
        totalFrames: frames.length,
        allMeasurements: validHeights,
      );

    } catch (e) {
      debugPrint('❌ Height measurement error: $e');
      return HeightMeasurementResult(
        success: false,
        errorMessage: 'Error measuring height: $e',
      );
    }
  }

  /// Calculate height from a single pose using the Python algorithm
  /// Returns height in cm, or null if calculation failed
  double? _calculateHeightFromPose(Pose pose) {
    try {
      // Get right hand index finger tip (landmark 20)
      final rightIndexFinger = pose.landmarks[PoseLandmarkType.rightIndex];
      if (rightIndexFinger == null) return null;

      final fingerX = rightIndexFinger.x;
      final fingerY = rightIndexFinger.y;

      // Get right foot landmarks - try RIGHT_FOOT_INDEX first, then RIGHT_HEEL
      PoseLandmark? rightFoot;
      
      // Try right foot index first
      final rightFootIndex = pose.landmarks[PoseLandmarkType.rightFootIndex];
      if (rightFootIndex != null && rightFootIndex.likelihood > 0.3) {
        rightFoot = rightFootIndex;
      } else {
        // Try right heel as fallback
        final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
        if (rightHeel != null && rightHeel.likelihood > 0.3) {
          rightFoot = rightHeel;
        }
      }

      if (rightFoot == null) return null;

      final toeX = rightFoot.x;
      final toeY = rightFoot.y;

      // Sanity check: foot must be clearly below finger
      if (toeY <= fingerY + 100) return null;

      // Calculate reference distance (finger to foot = 100 cm)
      final refPixels = _distance(fingerX, fingerY, toeX, toeY);
      if (refPixels < 100) return null; // Sanity check

      // Find top of head - highest visible point among ears, eyes, nose
      final headCandidates = [
        pose.landmarks[PoseLandmarkType.leftEar],
        pose.landmarks[PoseLandmarkType.rightEar],
        pose.landmarks[PoseLandmarkType.leftEye],
        pose.landmarks[PoseLandmarkType.rightEye],
        pose.landmarks[PoseLandmarkType.nose],
      ];

      double headYMin = double.infinity;
      double headX = fingerX;

      for (final landmark in headCandidates) {
        if (landmark != null && landmark.likelihood > 0.2) {
          if (landmark.y < headYMin) {
            headYMin = landmark.y;
            headX = landmark.x;
          }
        }
      }

      if (headYMin == double.infinity) return null;

      // Calculate distance from finger to top of head
      final headPixels = _distance(fingerX, fingerY, headX, headYMin);

      // Calculate height using proportional scaling
      final missingCm = headPixels * (100.0 / refPixels);
      final totalHeight = 100.0 + missingCm;

      // Sanity check: height should be reasonable (50-250 cm)
      if (totalHeight < 50 || totalHeight > 250) return null;

      return totalHeight;

    } catch (e) {
      debugPrint('Error calculating height from pose: $e');
      return null;
    }
  }

  /// Calculate Euclidean distance between two points
  double _distance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  /// Extract frames from video at regular intervals
  Future<List<String>> _extractFramesFromVideo(String videoPath, {int maxFrames = 30}) async {
    List<String> framePaths = [];
    final tempDir = await getTemporaryDirectory();

    try {
      // Extract frames at intervals (e.g., every 500ms for a 15-second video)
      for (int i = 0; i < maxFrames; i++) {
        final timeMs = (i * 500); // Extract frame every 500ms
        
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 75,
        );

        if (uint8list != null) {
          final framePath = '${tempDir.path}/height_frame_$i.jpg';
          final file = File(framePath);
          await file.writeAsBytes(uint8list);
          framePaths.add(framePath);
        }
      }
    } catch (e) {
      debugPrint('Error extracting frames: $e');
    }

    return framePaths;
  }

  /// Dispose resources
  void dispose() {
    _poseDetector.close();
  }
}

/// Result of height measurement
class HeightMeasurementResult {
  final bool success;
  final double? heightInCm;
  final String? errorMessage;
  final int? detectedFrames;
  final int? totalFrames;
  final List<double>? allMeasurements;

  HeightMeasurementResult({
    required this.success,
    this.heightInCm,
    this.errorMessage,
    this.detectedFrames,
    this.totalFrames,
    this.allMeasurements,
  });

  /// Get height in feet and inches
  String get heightInFeet {
    if (heightInCm == null) return 'N/A';
    final totalInches = heightInCm! / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '$feet\' $inches"';
  }

  /// Get height in meters
  double? get heightInMeters {
    if (heightInCm == null) return null;
    return heightInCm! / 100;
  }
}

