import 'dart:ui';
import 'dart:typed_data';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Service wrapper for ML Kit Pose Detection
class PoseDetectorService {
  late final PoseDetector _poseDetector;
  bool _isInitialized = false;

  /// Initialize the pose detector
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.base,
    );
    
    _poseDetector = PoseDetector(options: options);
    _isInitialized = true;
  }

  /// Process a single image and return detected poses
  Future<List<Pose>> processImage(InputImage inputImage) async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _poseDetector.processImage(inputImage);
  }

  /// Process a video file frame by frame
  /// Returns a list of poses for each frame, or null if no pose detected
  Future<List<Pose?>> processVideoFrames(
    List<Uint8List> frames,
    int width,
    int height,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    final List<Pose?> results = [];
    
    for (final frame in frames) {
      final inputImage = InputImage.fromBytes(
        bytes: frame,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
      
      final poses = await _poseDetector.processImage(inputImage);
      results.add(poses.isNotEmpty ? poses.first : null);
    }
    
    return results;
  }

  /// Extract specific landmark Y coordinate from a pose
  /// Returns null if landmark is not visible enough
  static double? getLandmarkY(Pose? pose, PoseLandmarkType type, {double minLikelihood = 0.2}) {
    if (pose == null) return null;
    
    final landmark = pose.landmarks[type];
    if (landmark == null) return null;
    if (landmark.likelihood < minLikelihood) return null;
    
    return landmark.y;
  }

  /// Get the mean Y of left and right landmarks
  static double? getMeanLandmarkY(
    Pose? pose,
    PoseLandmarkType leftType,
    PoseLandmarkType rightType, {
    double minLikelihood = 0.05,
  }) {
    if (pose == null) return null;
    
    final leftLandmark = pose.landmarks[leftType];
    final rightLandmark = pose.landmarks[rightType];
    
    double? leftY, rightY;
    
    if (leftLandmark != null && leftLandmark.likelihood >= minLikelihood) {
      leftY = leftLandmark.y;
    }
    if (rightLandmark != null && rightLandmark.likelihood >= minLikelihood) {
      rightY = rightLandmark.y;
    }
    
    if (leftY != null && rightY != null) {
      return (leftY + rightY) / 2;
    } else if (leftY != null) {
      return leftY;
    } else if (rightY != null) {
      return rightY;
    }
    
    return null;
  }

  /// Compute scale (meters per pixel) from known height
  /// Uses nose to ankle distance
  static double? computeScaleFromHeight(
    Pose? pose,
    double knownHeightM, {
    double minNoseVisibility = 0.2,
    double minAnkleVisibility = 0.05,
  }) {
    if (pose == null) return null;
    
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || nose.likelihood < minNoseVisibility) return null;
    
    final leftAnkleOk = leftAnkle != null && leftAnkle.likelihood >= minAnkleVisibility;
    final rightAnkleOk = rightAnkle != null && rightAnkle.likelihood >= minAnkleVisibility;
    
    if (!leftAnkleOk && !rightAnkleOk) return null;
    
    final noseY = nose.y;
    double ankleY;
    
    if (leftAnkleOk && rightAnkleOk) {
      ankleY = (leftAnkle!.y + rightAnkle!.y) / 2;
    } else if (leftAnkleOk) {
      ankleY = leftAnkle!.y;
    } else {
      ankleY = rightAnkle!.y;
    }
    
    final pixelHeight = (ankleY - noseY).abs();
    if (pixelHeight < 5) return null;
    
    return knownHeightM / pixelHeight;
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _poseDetector.close();
      _isInitialized = false;
    }
  }
}

