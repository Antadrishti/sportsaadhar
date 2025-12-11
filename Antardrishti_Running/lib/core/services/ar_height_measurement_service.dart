import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Measurement state for the AR height measurement flow
enum ARMeasurementState {
  initializing,
  detectingGround,
  waitingForPerson,
  trackingPerson,
  stabilizing,
  measuring,
  completed,
  error,
}

/// A single pose sample with timestamp and metrics
class PoseSample {
  final Pose pose;
  final int frameWidth;
  final int frameHeight;
  final double confidence;
  final DateTime timestamp;
  
  // Calculated 2D positions
  final double? headY;
  final double? ankleY;
  final double? pixelHeight;
  
  PoseSample({
    required this.pose,
    required this.frameWidth,
    required this.frameHeight,
    required this.confidence,
    required this.timestamp,
    this.headY,
    this.ankleY,
    this.pixelHeight,
  });
}

/// Result of AR height measurement
class ARHeightMeasurementResult {
  final bool success;
  final double? heightCm;
  final double? confidence;
  final String? errorMessage;
  final int samplesUsed;
  final double? standardDeviation;
  
  ARHeightMeasurementResult({
    required this.success,
    this.heightCm,
    this.confidence,
    this.errorMessage,
    this.samplesUsed = 0,
    this.standardDeviation,
  });
  
  String get heightInFeet {
    if (heightCm == null) return 'N/A';
    final totalInches = heightCm! / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '$feet\' $inches"';
  }
  
  double? get heightInMeters => heightCm != null ? heightCm! / 100 : null;
}

/// Callback for measurement state changes
typedef ARMeasurementStateCallback = void Function(
  ARMeasurementState state,
  String message,
  double? progress,
);

/// Callback for height updates during measurement
typedef ARHeightUpdateCallback = void Function(
  double? currentHeightCm,
  double confidence,
);

/// AR Height Measurement Service
/// 
/// Uses a combination of:
/// 1. Google MLKit Pose Detection for accurate 2D keypoint detection
/// 2. Camera intrinsics + distance estimation for 3D height calculation
/// 3. Anthropometric ratios for scale calibration
/// 4. Multi-frame averaging for stability and accuracy
class ARHeightMeasurementService {
  // Pose detector
  late PoseDetector _poseDetector;
  
  // Camera controller reference (used for frame size info)
  // ignore: unused_field
  CameraController? _cameraController;
  
  // Processing state
  bool _isProcessing = false;
  bool _isInitialized = false;
  ARMeasurementState _currentState = ARMeasurementState.initializing;
  
  // Pose history for stability
  final Queue<PoseSample> _poseHistory = Queue<PoseSample>();
  
  // Configuration
  static const int _stabilityFrames = 15;
  static const double _stabilityThreshold = 0.02; // 2% variance allowed
  static const int _measurementFrames = 20;
  
  // Camera parameters (will be calibrated)
  double _verticalFOV = 55.0; // degrees, typical for smartphone cameras
  double _focalLengthPixels = 1000.0; // Will be estimated
  
  // Ground plane detection (simulated using pose)
  bool _groundPlaneDetected = false;
  double? _estimatedDistanceM;
  
  // Callbacks
  ARMeasurementStateCallback? onStateChanged;
  ARHeightUpdateCallback? onHeightUpdate;
  
  // Measurement results accumulator
  final List<double> _heightMeasurements = [];
  
  ARHeightMeasurementService();
  
  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.accurate,
      ),
    );
    
    _isInitialized = true;
    _updateState(ARMeasurementState.detectingGround, 'Move phone to detect ground plane...');
  }
  
  /// Set the camera controller for frame processing
  void setCameraController(CameraController controller) {
    _cameraController = controller;
    
    // Estimate camera parameters from resolution
    final width = controller.value.previewSize?.width ?? 1920;
    final height = controller.value.previewSize?.height ?? 1080;
    
    // Estimate focal length in pixels (typical smartphone ~26mm equivalent)
    // f_pixels = (sensor_height_pixels / 2) / tan(FOV/2)
    _focalLengthPixels = (height / 2) / tan(_verticalFOV * pi / 360);
    
    debugPrint('📸 Camera initialized: ${width}x$height, estimated focal length: $_focalLengthPixels px');
  }
  
  /// Process a camera frame
  Future<void> processFrame(CameraImage image) async {
    if (!_isInitialized || _isProcessing) return;
    if (_currentState == ARMeasurementState.completed || 
        _currentState == ARMeasurementState.error) return;
    
    _isProcessing = true;
    
    try {
      // Convert camera image to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }
      
      // Detect pose
      final poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) {
        _handleNoPerson();
        _isProcessing = false;
        return;
      }
      
      if (poses.length > 1) {
        _handleMultiplePeople();
        _isProcessing = false;
        return;
      }
      
      final pose = poses.first;
      await _processPose(pose, image.width, image.height);
      
    } catch (e) {
      debugPrint('❌ Frame processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Convert CameraImage to InputImage for MLKit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;
      
      final plane = image.planes.first;
      
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }
  
  /// Process detected pose
  Future<void> _processPose(Pose pose, int frameWidth, int frameHeight) async {
    // Check if we have required landmarks
    final headTop = _getHeadTop(pose);
    final anklePos = _getAnklePosition(pose);
    
    if (headTop == null || anklePos == null) {
      _handleIncompletePose();
      return;
    }
    
    // Check visibility confidence
    final headConfidence = _getHeadConfidence(pose);
    final ankleConfidence = _getAnkleConfidence(pose);
    
    if (headConfidence < 0.3 || ankleConfidence < 0.3) {
      _handleLowConfidence();
      return;
    }
    
    // Check if person is fully in frame
    if (!_isPersonInFrame(pose, frameWidth, frameHeight)) {
      _handleOutOfFrame();
      return;
    }
    
    // Calculate pixel height (from head top to ankle)
    final pixelHeight = (anklePos.y - headTop.y).abs();
    
    // Create pose sample
    final sample = PoseSample(
      pose: pose,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      confidence: (headConfidence + ankleConfidence) / 2,
      timestamp: DateTime.now(),
      headY: headTop.y,
      ankleY: anklePos.y,
      pixelHeight: pixelHeight,
    );
    
    // Add to history
    _poseHistory.addLast(sample);
    if (_poseHistory.length > _stabilityFrames + _measurementFrames) {
      _poseHistory.removeFirst();
    }
    
    // Detect ground plane from ankle position stability
    if (!_groundPlaneDetected && _poseHistory.length >= 5) {
      _detectGroundFromPose();
    }
    
    // Update state based on pose stability
    if (_groundPlaneDetected) {
      _updateMeasurementState(sample);
    }
  }
  
  /// Get the top of the head position
  Point? _getHeadTop(Pose pose) {
    // Find the highest point among head landmarks
    final headLandmarks = [
      pose.landmarks[PoseLandmarkType.nose],
      pose.landmarks[PoseLandmarkType.leftEye],
      pose.landmarks[PoseLandmarkType.rightEye],
      pose.landmarks[PoseLandmarkType.leftEar],
      pose.landmarks[PoseLandmarkType.rightEar],
    ];
    
    double minY = double.infinity;
    double avgX = 0;
    int count = 0;
    
    for (final landmark in headLandmarks) {
      if (landmark != null && landmark.likelihood > 0.3) {
        if (landmark.y < minY) {
          minY = landmark.y;
        }
        avgX += landmark.x;
        count++;
      }
    }
    
    if (count == 0 || minY == double.infinity) return null;
    
    // Add estimated distance to actual top of head (nose/eyes are not the top)
    // Head top is approximately 10-15% of head height above eyes
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final ear = pose.landmarks[PoseLandmarkType.leftEar] ?? 
                pose.landmarks[PoseLandmarkType.rightEar];
    
    if (nose != null && ear != null) {
      final headHeight = (ear.y - nose.y).abs() * 2.5; // Estimate full head height
      minY -= headHeight * 0.15; // Add top of head offset
    }
    
    return Point(avgX / count, minY);
  }
  
  /// Get average ankle position
  Point? _getAnklePosition(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftAnkle != null && rightAnkle != null) {
      if (leftAnkle.likelihood > 0.3 && rightAnkle.likelihood > 0.3) {
        return Point(
          (leftAnkle.x + rightAnkle.x) / 2,
          max(leftAnkle.y, rightAnkle.y), // Use lower ankle for ground reference
        );
      }
    }
    
    // Fallback to single ankle
    if (leftAnkle != null && leftAnkle.likelihood > 0.3) {
      return Point(leftAnkle.x, leftAnkle.y);
    }
    if (rightAnkle != null && rightAnkle.likelihood > 0.3) {
      return Point(rightAnkle.x, rightAnkle.y);
    }
    
    // Try foot index as fallback
    final leftFoot = pose.landmarks[PoseLandmarkType.leftFootIndex];
    final rightFoot = pose.landmarks[PoseLandmarkType.rightFootIndex];
    
    if (leftFoot != null && rightFoot != null) {
      return Point(
        (leftFoot.x + rightFoot.x) / 2,
        max(leftFoot.y, rightFoot.y),
      );
    }
    
    return null;
  }
  
  double _getHeadConfidence(Pose pose) {
    final landmarks = [
      pose.landmarks[PoseLandmarkType.nose],
      pose.landmarks[PoseLandmarkType.leftEye],
      pose.landmarks[PoseLandmarkType.rightEye],
    ];
    
    double total = 0;
    int count = 0;
    for (final lm in landmarks) {
      if (lm != null) {
        total += lm.likelihood;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }
  
  double _getAnkleConfidence(Pose pose) {
    final left = pose.landmarks[PoseLandmarkType.leftAnkle];
    final right = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (left != null && right != null) {
      return (left.likelihood + right.likelihood) / 2;
    }
    return left?.likelihood ?? right?.likelihood ?? 0;
  }
  
  bool _isPersonInFrame(Pose pose, int width, int height) {
    const margin = 20.0;
    
    // Check key points are within frame
    final keyPoints = [
      pose.landmarks[PoseLandmarkType.nose],
      pose.landmarks[PoseLandmarkType.leftAnkle],
      pose.landmarks[PoseLandmarkType.rightAnkle],
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.rightShoulder],
    ];
    
    for (final point in keyPoints) {
      if (point != null && point.likelihood > 0.3) {
        if (point.x < margin || point.x > width - margin ||
            point.y < margin || point.y > height - margin) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Detect ground plane from ankle position stability
  void _detectGroundFromPose() {
    if (_poseHistory.length < 5) return;
    
    // Check if ankle Y positions are stable (person standing on ground)
    final ankleYs = _poseHistory
        .where((s) => s.ankleY != null)
        .map((s) => s.ankleY!)
        .toList();
    
    if (ankleYs.length < 5) return;
    
    final avgAnkleY = ankleYs.reduce((a, b) => a + b) / ankleYs.length;
    final variance = ankleYs
        .map((y) => pow(y - avgAnkleY, 2))
        .reduce((a, b) => a + b) / ankleYs.length;
    final stdDev = sqrt(variance);
    
    // If ankle position is stable (low variance), ground is detected
    final frameHeight = _poseHistory.last.frameHeight;
    if (stdDev / frameHeight < 0.02) {
      _groundPlaneDetected = true;
      _updateState(ARMeasurementState.trackingPerson, 'Ground detected! Stand still...');
      debugPrint('🎯 Ground plane detected, ankle variance: ${stdDev / frameHeight}');
    }
  }
  
  /// Update measurement state based on pose stability
  void _updateMeasurementState(PoseSample currentSample) {
    if (_poseHistory.length < _stabilityFrames) {
      _updateState(
        ARMeasurementState.stabilizing,
        'Hold still... ${_poseHistory.length}/$_stabilityFrames',
        _poseHistory.length / _stabilityFrames,
      );
      return;
    }
    
    // Check pose stability
    if (_isPoseStable()) {
      if (_currentState != ARMeasurementState.measuring) {
        _updateState(ARMeasurementState.measuring, 'Measuring height...');
      }
      
      // Calculate height for this frame
      final heightCm = _calculateHeightFromSample(currentSample);
      if (heightCm != null && heightCm > 50 && heightCm < 250) {
        _heightMeasurements.add(heightCm);
        
        // Notify with current estimate
        final avgHeight = _heightMeasurements.reduce((a, b) => a + b) / 
                          _heightMeasurements.length;
        final confidence = min(1.0, _heightMeasurements.length / _measurementFrames);
        
        onHeightUpdate?.call(avgHeight, confidence);
        
        // Check if we have enough measurements
        if (_heightMeasurements.length >= _measurementFrames) {
          _completeMeasurement();
        }
      }
    } else {
      _heightMeasurements.clear();
      _updateState(
        ARMeasurementState.stabilizing,
        'Please stand still...',
      );
    }
  }
  
  /// Check if the pose is stable (low variance over recent frames)
  bool _isPoseStable() {
    if (_poseHistory.length < _stabilityFrames) return false;
    
    final recentSamples = _poseHistory.toList().sublist(
      max(0, _poseHistory.length - _stabilityFrames),
    );
    
    // Check pixel height variance
    final heights = recentSamples
        .where((s) => s.pixelHeight != null)
        .map((s) => s.pixelHeight!)
        .toList();
    
    if (heights.length < _stabilityFrames ~/ 2) return false;
    
    final avgHeight = heights.reduce((a, b) => a + b) / heights.length;
    final variance = heights
        .map((h) => pow(h - avgHeight, 2))
        .reduce((a, b) => a + b) / heights.length;
    final relativeStdDev = sqrt(variance) / avgHeight;
    
    return relativeStdDev < _stabilityThreshold;
  }
  
  /// Calculate height from a single pose sample
  /// 
  /// Method: Distance estimation + perspective projection
  /// 
  /// 1. Estimate distance using shoulder width as reference
  ///    (average adult shoulder width ~40cm for women, ~45cm for men, use 42cm average)
  /// 2. Calculate real height using: H = (pixel_height / focal_length) * distance
  double? _calculateHeightFromSample(PoseSample sample) {
    if (sample.pixelHeight == null) return null;
    
    final pose = sample.pose;
    
    // Method 1: Use shoulder width as reference for distance estimation
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    double? distanceM;
    
    if (leftShoulder != null && rightShoulder != null &&
        leftShoulder.likelihood > 0.5 && rightShoulder.likelihood > 0.5) {
      
      final shoulderWidthPixels = (rightShoulder.x - leftShoulder.x).abs();
      const avgShoulderWidthCm = 42.0; // Average shoulder width in cm
      
      // Distance = (real_width * focal_length) / pixel_width
      distanceM = (avgShoulderWidthCm / 100) * _focalLengthPixels / shoulderWidthPixels;
    }
    
    // Method 2: Use hip width as secondary reference
    if (distanceM == null) {
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      
      if (leftHip != null && rightHip != null &&
          leftHip.likelihood > 0.5 && rightHip.likelihood > 0.5) {
        
        final hipWidthPixels = (rightHip.x - leftHip.x).abs();
        const avgHipWidthCm = 36.0; // Average hip width
        
        distanceM = (avgHipWidthCm / 100) * _focalLengthPixels / hipWidthPixels;
      }
    }
    
    if (distanceM == null || distanceM < 0.5 || distanceM > 5.0) {
      // Distance out of reasonable range, use fallback
      distanceM = 2.0; // Assume 2m distance as fallback
    }
    
    _estimatedDistanceM = distanceM;
    
    // Calculate real height using perspective projection formula
    // real_height = (pixel_height / focal_length) * distance
    final heightM = (sample.pixelHeight! / _focalLengthPixels) * distanceM;
    final heightCm = heightM * 100;
    
    // Apply correction factor for pose detection offset
    // (MLKit detects eyes/nose, not actual top of head - we compensated in _getHeadTop,
    // but may need fine-tuning)
    final correctedHeightCm = heightCm * 1.02; // 2% correction factor
    
    debugPrint('📏 Frame height: ${sample.pixelHeight!.toStringAsFixed(0)}px, '
               'distance: ${distanceM.toStringAsFixed(2)}m, '
               'height: ${correctedHeightCm.toStringAsFixed(1)}cm');
    
    return correctedHeightCm;
  }
  
  /// Complete measurement and calculate final result
  void _completeMeasurement() {
    if (_heightMeasurements.isEmpty) {
      _updateState(ARMeasurementState.error, 'No valid measurements captured');
      return;
    }
    
    // Remove outliers using IQR method
    final sortedMeasurements = List<double>.from(_heightMeasurements)..sort();
    final q1Index = sortedMeasurements.length ~/ 4;
    final q3Index = (sortedMeasurements.length * 3) ~/ 4;
    final q1 = sortedMeasurements[q1Index];
    final q3 = sortedMeasurements[q3Index];
    final iqr = q3 - q1;
    
    final filteredMeasurements = sortedMeasurements
        .where((h) => h >= q1 - 1.5 * iqr && h <= q3 + 1.5 * iqr)
        .toList();
    
    if (filteredMeasurements.isEmpty) {
      filteredMeasurements.addAll(sortedMeasurements);
    }
    
    // Calculate final height (median for robustness)
    final medianIndex = filteredMeasurements.length ~/ 2;
    final finalHeightCm = filteredMeasurements[medianIndex];
    
    // Calculate standard deviation for confidence
    final avgHeight = filteredMeasurements.reduce((a, b) => a + b) / 
                      filteredMeasurements.length;
    final variance = filteredMeasurements
        .map((h) => pow(h - avgHeight, 2))
        .reduce((a, b) => a + b) / filteredMeasurements.length;
    final stdDev = sqrt(variance);
    
    // Confidence based on standard deviation (lower is better)
    // <1cm stdDev = 100% confidence, >5cm stdDev = 50% confidence
    final confidence = max(0.5, min(1.0, 1.0 - (stdDev - 1) / 8));
    
    _updateState(
      ARMeasurementState.completed,
      'Height: ${finalHeightCm.toStringAsFixed(1)} cm',
    );
    
    debugPrint('✅ Measurement complete: ${finalHeightCm.toStringAsFixed(1)} cm '
               '(std dev: ${stdDev.toStringAsFixed(2)} cm, '
               'samples: ${filteredMeasurements.length})');
    
    onHeightUpdate?.call(finalHeightCm, confidence);
  }
  
  /// Get the final measurement result
  ARHeightMeasurementResult getResult() {
    if (_currentState != ARMeasurementState.completed || 
        _heightMeasurements.isEmpty) {
      return ARHeightMeasurementResult(
        success: false,
        errorMessage: 'Measurement not completed',
      );
    }
    
    final sortedMeasurements = List<double>.from(_heightMeasurements)..sort();
    final medianIndex = sortedMeasurements.length ~/ 2;
    final finalHeightCm = sortedMeasurements[medianIndex];
    
    final avgHeight = sortedMeasurements.reduce((a, b) => a + b) / 
                      sortedMeasurements.length;
    final variance = sortedMeasurements
        .map((h) => pow(h - avgHeight, 2))
        .reduce((a, b) => a + b) / sortedMeasurements.length;
    final stdDev = sqrt(variance);
    final confidence = max(0.5, min(1.0, 1.0 - (stdDev - 1) / 8));
    
    return ARHeightMeasurementResult(
      success: true,
      heightCm: finalHeightCm,
      confidence: confidence,
      samplesUsed: sortedMeasurements.length,
      standardDeviation: stdDev,
    );
  }
  
  // State change handlers
  void _handleNoPerson() {
    if (_currentState != ARMeasurementState.waitingForPerson &&
        _currentState != ARMeasurementState.detectingGround) {
      _poseHistory.clear();
      _heightMeasurements.clear();
      _updateState(
        ARMeasurementState.waitingForPerson,
        'Walk into view and stand straight',
      );
    }
  }
  
  void _handleMultiplePeople() {
    _poseHistory.clear();
    _heightMeasurements.clear();
    _updateState(
      ARMeasurementState.error,
      'Multiple people detected!\nOnly one person should be visible.',
    );
  }
  
  void _handleIncompletePose() {
    if (_currentState != ARMeasurementState.error) {
      _updateState(
        ARMeasurementState.error,
        'Full body not visible.\nMake sure head and feet are in frame.',
      );
    }
  }
  
  void _handleLowConfidence() {
    _updateState(
      ARMeasurementState.error,
      'Detection confidence low.\nImprove lighting and stand clearly.',
    );
  }
  
  void _handleOutOfFrame() {
    _poseHistory.clear();
    _updateState(
      ARMeasurementState.error,
      'Stand back further.\nYour entire body must be visible.',
    );
  }
  
  void _updateState(ARMeasurementState state, String message, [double? progress]) {
    _currentState = state;
    onStateChanged?.call(state, message, progress);
  }
  
  /// Reset for a new measurement
  void reset() {
    _poseHistory.clear();
    _heightMeasurements.clear();
    _groundPlaneDetected = false;
    _estimatedDistanceM = null;
    _currentState = ARMeasurementState.detectingGround;
    _updateState(ARMeasurementState.detectingGround, 'Point camera at floor...');
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    _poseDetector.close();
    _isInitialized = false;
  }
  
  // Getters
  ARMeasurementState get currentState => _currentState;
  bool get isInitialized => _isInitialized;
  double? get estimatedDistance => _estimatedDistanceM;
  int get sampleCount => _heightMeasurements.length;
}

/// Simple point class for 2D coordinates
class Point {
  final double x;
  final double y;
  
  Point(this.x, this.y);
}

