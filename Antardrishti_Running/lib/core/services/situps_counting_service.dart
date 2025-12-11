import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// Service for counting sit-ups using MediaPipe pose detection
/// Based on shoulder-hip-knee angle tracking
class SitupsCountingService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  /// Count sit-ups from a video file
  /// Returns the total number of sit-ups performed
  Future<SitupsCountResult> countSitupsFromVideo(String videoPath) async {
    int counter = 0;
    bool wasBelow50 = false;
    List<double> angles = [];

    try {
      // Extract frames from video at regular intervals
      final frames = await _extractFramesFromVideo(videoPath, maxFrames: 200);
      
      if (frames.isEmpty) {
        return SitupsCountResult(
          success: false,
          errorMessage: 'Failed to extract frames from video',
        );
      }

      debugPrint('📹 Extracted ${frames.length} frames for sit-ups analysis');

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        try {
          final inputImage = InputImage.fromFilePath(frames[i]);
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty) {
            final pose = poses.first;
            
            // Auto-detect visible side (left or right)
            final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
            final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
            
            bool useLeftSide = false;
            if (leftHip != null && rightHip != null) {
              useLeftSide = leftHip.likelihood > rightHip.likelihood;
            } else if (leftHip != null) {
              useLeftSide = true;
            }
            
            // Get landmarks based on visible side
            PoseLandmark? shoulder, hip, knee;
            
            if (useLeftSide) {
              shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
              hip = pose.landmarks[PoseLandmarkType.leftHip];
              knee = pose.landmarks[PoseLandmarkType.leftKnee];
            } else {
              shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
              hip = pose.landmarks[PoseLandmarkType.rightHip];
              knee = pose.landmarks[PoseLandmarkType.rightKnee];
            }
            
            // Check if all landmarks are available and visible
            if (shoulder != null && hip != null && knee != null &&
                shoulder.likelihood > 0.5 && hip.likelihood > 0.5 && knee.likelihood > 0.5) {
              
              // Calculate angle at hip joint
              final angle = _calculateAngle(
                [shoulder.x, shoulder.y],
                [hip.x, hip.y],
                [knee.x, knee.y],
              );
              
              angles.add(angle);
              
              // Counting logic from Python code
              if (angle <= 50) {
                wasBelow50 = true;
                debugPrint('Frame $i: UP position (angle: ${angle.toStringAsFixed(1)}°)');
              }
              
              // When angle starts increasing again after being below 50 → count 1 sit-up
              if (wasBelow50 && angle > 60) {
                counter++;
                wasBelow50 = false;
                debugPrint('✅ SIT-UP #$counter COUNTED! (angle: ${angle.toStringAsFixed(1)}°)');
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

      if (counter == 0 && angles.isEmpty) {
        return SitupsCountResult(
          success: false,
          errorMessage: 'No sit-ups detected. Make sure your shoulder, hip, and knee are visible throughout the video.',
          framesProcessed: frames.length,
        );
      }

      debugPrint('📊 Final Count: $counter sit-ups');

      return SitupsCountResult(
        success: true,
        count: counter,
        framesProcessed: frames.length,
        framesWithPose: angles.length,
      );

    } catch (e) {
      debugPrint('❌ Sit-ups counting error: $e');
      return SitupsCountResult(
        success: false,
        errorMessage: 'Error counting sit-ups: $e',
      );
    }
  }

  /// Calculate angle at hip joint (shoulder-hip-knee)
  /// Based on the Python algorithm using dot product
  double _calculateAngle(List<double> p1, List<double> p2, List<double> p3) {
    // Vectors from hip (p2) to shoulder (p1) and knee (p3)
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
          final framePath = '${tempDir.path}/situps_frame_$i.jpg';
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

/// Result of sit-ups counting
class SitupsCountResult {
  final bool success;
  final int? count;
  final String? errorMessage;
  final int? framesProcessed;
  final int? framesWithPose;

  SitupsCountResult({
    required this.success,
    this.count,
    this.errorMessage,
    this.framesProcessed,
    this.framesWithPose,
  });

  /// Get formatted count for display
  String get formattedCount {
    if (count == null) return 'N/A';
    return count == 1 ? '1 sit-up' : '$count sit-ups';
  }
}



