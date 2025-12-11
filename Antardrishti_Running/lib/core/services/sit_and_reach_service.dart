import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// Service for measuring flexibility using MediaPipe pose detection
/// Based on ear-hip-knee angle tracking (lower angle = better flexibility)
class SitAndReachService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  /// Measure flexibility from a video file
  /// Returns the best (minimum) angle achieved
  Future<FlexibilityMeasurementResult> measureFlexibilityFromVideo(String videoPath) async {
    double bestAngle = 180.0; // Start high (worst flexibility)
    List<double> angles = [];

    try {
      // Extract frames from video at regular intervals
      final frames = await _extractFramesFromVideo(videoPath, maxFrames: 200);
      
      if (frames.isEmpty) {
        return FlexibilityMeasurementResult(
          success: false,
          errorMessage: 'Failed to extract frames from video',
        );
      }

      debugPrint('📹 Extracted ${frames.length} frames for flexibility analysis');

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        try {
          final inputImage = InputImage.fromFilePath(frames[i]);
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty) {
            final pose = poses.first;
            
            // Get landmarks (left side)
            final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
            final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
            final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
            
            // Check if all landmarks are available and visible
            if (leftEar != null && leftHip != null && leftKnee != null &&
                leftEar.likelihood > 0.5 && leftHip.likelihood > 0.5 && leftKnee.likelihood > 0.5) {
              
              // Calculate angle at hip joint (ear-hip-knee)
              final angle = _calculateAngle(
                [leftEar.x, leftEar.y],
                [leftHip.x, leftHip.y],
                [leftKnee.x, leftKnee.y],
              );
              
              angles.add(angle);
              
              // Track best (minimum) angle
              if (angle < bestAngle) {
                bestAngle = angle;
                debugPrint('✅ New best angle: ${bestAngle.toStringAsFixed(1)}° at frame $i');
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing frame $i: $e');
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

      if (angles.isEmpty) {
        return FlexibilityMeasurementResult(
          success: false,
          errorMessage: 'No flexibility measurements detected. Make sure your ear, hip, and knee are visible in side view.',
          framesProcessed: frames.length,
        );
      }

      // Determine flexibility rating
      final rating = _getFlexibilityRating(bestAngle);

      debugPrint('📊 Best Flexibility Angle: ${bestAngle.toStringAsFixed(1)}°');
      debugPrint('⭐ Rating: $rating');

      return FlexibilityMeasurementResult(
        success: true,
        bestAngle: bestAngle,
        rating: rating,
        framesProcessed: frames.length,
        framesWithPose: angles.length,
      );

    } catch (e) {
      debugPrint('❌ Flexibility measurement error: $e');
      return FlexibilityMeasurementResult(
        success: false,
        errorMessage: 'Error measuring flexibility: $e',
      );
    }
  }

  /// Calculate angle at hip joint (ear-hip-knee)
  /// Based on the Python algorithm using dot product
  double _calculateAngle(List<double> p1, List<double> p2, List<double> p3) {
    // Vectors from hip (p2) to ear (p1) and knee (p3)
    final ba = [p1[0] - p2[0], p1[1] - p2[1]];
    final bc = [p3[0] - p2[0], p3[1] - p2[1]];
    
    // Dot product
    final dotProduct = ba[0] * bc[0] + ba[1] * bc[1];
    
    // Magnitudes
    final magBA = sqrt(ba[0] * ba[0] + ba[1] * ba[1]);
    final magBC = sqrt(bc[0] * bc[0] + bc[1] * bc[1]);
    
    // Cosine
    final cosine = dotProduct / (magBA * magBC + 1e-6);
    
    // Angle in degrees
    final angle = acos(cosine.clamp(-1.0, 1.0)) * 180 / pi;
    
    return angle;
  }

  /// Get flexibility rating based on angle
  /// Lower angle = Better flexibility
  String _getFlexibilityRating(double angle) {
    if (angle <= 30) return 'elite';
    if (angle <= 50) return 'excellent';
    if (angle <= 70) return 'very_good';
    return 'good';
  }

  /// Get human-readable rating text
  String getFlexibilityRatingText(String rating) {
    switch (rating) {
      case 'elite':
        return 'Elite / World-Class';
      case 'excellent':
        return 'Excellent';
      case 'very_good':
        return 'Very Good';
      case 'good':
        return 'Good - Keep Stretching';
      default:
        return 'Good';
    }
  }

  /// Extract frames from video at regular intervals
  Future<List<String>> _extractFramesFromVideo(String videoPath, {int maxFrames = 200}) async {
    List<String> framePaths = [];
    final tempDir = await getTemporaryDirectory();

    try {
      // Extract frames at intervals (e.g., every 100ms)
      for (int i = 0; i < maxFrames; i++) {
        final timeMs = (i * 100); // Extract frame every 100ms
        
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 75,
        );

        if (uint8list != null) {
          final framePath = '${tempDir.path}/sitreach_frame_$i.jpg';
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

/// Result of flexibility measurement
class FlexibilityMeasurementResult {
  final bool success;
  final double? bestAngle;
  final String? rating;
  final String? errorMessage;
  final int? framesProcessed;
  final int? framesWithPose;

  FlexibilityMeasurementResult({
    required this.success,
    this.bestAngle,
    this.rating,
    this.errorMessage,
    this.framesProcessed,
    this.framesWithPose,
  });

  /// Get formatted angle for display
  String get formattedAngle {
    if (bestAngle == null) return 'N/A';
    return '${bestAngle!.toStringAsFixed(1)}°';
  }
}



