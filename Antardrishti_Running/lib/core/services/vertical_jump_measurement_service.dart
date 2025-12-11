import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// Service for measuring vertical jump height using MediaPipe pose detection
/// Based on toe tracking algorithm with auto-calibration
class VerticalJumpMeasurementService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  /// Measure vertical jump height from a video file
  /// Returns the jump height in centimeters
  Future<JumpMeasurementResult> measureJumpFromVideo(
    String videoPath,
    double personHeightCm,
  ) async {
    bool calibrated = false;
    double? cmPerPixel;
    double? groundToeY;
    double? highestToeY;
    List<double> jumpHeights = [];

    try {
      // Extract frames from video at regular intervals
      final frames = await _extractFramesFromVideo(videoPath, maxFrames: 50);
      
      if (frames.isEmpty) {
        return JumpMeasurementResult(
          success: false,
          errorMessage: 'Failed to extract frames from video',
        );
      }

      debugPrint('📹 Extracted ${frames.length} frames for jump analysis');

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        try {
          final inputImage = InputImage.fromFilePath(frames[i]);
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty) {
            final pose = poses.first;
            
            // Get toe positions
            final leftToe = pose.landmarks[PoseLandmarkType.leftFootIndex];
            final rightToe = pose.landmarks[PoseLandmarkType.rightFootIndex];
            final nose = pose.landmarks[PoseLandmarkType.nose];
            
            if (leftToe != null && rightToe != null && nose != null) {
              // Frame dimensions (assuming normalized coordinates 0-1)
              // We'll use a reference height of 1000 pixels
              const frameHeight = 1000.0;
              
              final leftToeY = leftToe.y * frameHeight;
              final rightToeY = rightToe.y * frameHeight;
              final toeY = (leftToeY + rightToeY) / 2;
              
              // Calibration phase: detect standing position
              if (!calibrated) {
                final noseY = nose.y * frameHeight;
                final pixelHeight = toeY - noseY;
                
                // Check if full body is visible (nose to toe > 300 pixels)
                if (pixelHeight > 300) {
                  cmPerPixel = personHeightCm / pixelHeight;
                  groundToeY = toeY;
                  calibrated = true;
                  debugPrint('✅ Calibrated at frame $i: ${cmPerPixel!.toStringAsFixed(4)} cm/pixel');
                }
              }
              
              // Jump tracking phase: find highest toe position
              if (calibrated && cmPerPixel != null && groundToeY != null) {
                if (highestToeY == null || toeY < highestToeY!) {
                  highestToeY = toeY;
                }
                
                // Calculate current rise
                final risePx = groundToeY! - toeY;
                final riseCm = risePx * cmPerPixel!;
                
                if (riseCm > 0 && riseCm < 200) { // Sanity check (0-200 cm)
                  jumpHeights.add(riseCm);
                  debugPrint('Frame $i: Toe lift = ${riseCm.toStringAsFixed(1)} cm');
                }
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

      // Calculate final result
      if (!calibrated) {
        return JumpMeasurementResult(
          success: false,
          errorMessage: 'Failed to calibrate. Make sure you stand still with full body visible for 2-3 seconds.',
          calibrated: false,
        );
      }

      if (highestToeY == null || groundToeY == null || cmPerPixel == null) {
        return JumpMeasurementResult(
          success: false,
          errorMessage: 'Failed to detect jump. Make sure both feet are visible throughout the video.',
          calibrated: true,
        );
      }

      final finalJumpHeightCm = (groundToeY! - highestToeY!) * cmPerPixel!;
      
      // Sanity check
      if (finalJumpHeightCm < 0 || finalJumpHeightCm > 200) {
        return JumpMeasurementResult(
          success: false,
          errorMessage: 'Invalid jump height detected. Please retry with better lighting and camera positioning.',
          calibrated: true,
        );
      }

      debugPrint('📊 Final Jump Height: ${finalJumpHeightCm.toStringAsFixed(1)} cm');

      return JumpMeasurementResult(
        success: true,
        jumpHeightCm: finalJumpHeightCm,
        calibrated: true,
        framesProcessed: frames.length,
        framesWithJump: jumpHeights.length,
      );

    } catch (e) {
      debugPrint('❌ Jump measurement error: $e');
      return JumpMeasurementResult(
        success: false,
        errorMessage: 'Error measuring jump: $e',
      );
    }
  }

  /// Extract frames from video at regular intervals
  Future<List<String>> _extractFramesFromVideo(String videoPath, {int maxFrames = 50}) async {
    List<String> framePaths = [];
    final tempDir = await getTemporaryDirectory();

    try {
      // Extract frames at intervals (e.g., every 200ms for a 10-second video)
      for (int i = 0; i < maxFrames; i++) {
        final timeMs = (i * 200); // Extract frame every 200ms
        
        final uint8list = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 75,
        );

        if (uint8list != null) {
          final framePath = '${tempDir.path}/jump_frame_$i.jpg';
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

/// Result of vertical jump measurement
class JumpMeasurementResult {
  final bool success;
  final double? jumpHeightCm;
  final String? errorMessage;
  final bool? calibrated;
  final int? framesProcessed;
  final int? framesWithJump;

  JumpMeasurementResult({
    required this.success,
    this.jumpHeightCm,
    this.errorMessage,
    this.calibrated,
    this.framesProcessed,
    this.framesWithJump,
  });

  /// Get jump height in inches
  double? get jumpHeightInches {
    if (jumpHeightCm == null) return null;
    return jumpHeightCm! / 2.54;
  }

  /// Get jump height in meters
  double? get jumpHeightMeters {
    if (jumpHeightCm == null) return null;
    return jumpHeightCm! / 100;
  }

  /// Format jump height for display
  String get formattedJumpHeight {
    if (jumpHeightCm == null) return 'N/A';
    return '${jumpHeightCm!.toStringAsFixed(1)} cm (${jumpHeightInches!.toStringAsFixed(1)}" inches)';
  }
}

