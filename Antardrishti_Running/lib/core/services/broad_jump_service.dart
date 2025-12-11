import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as video_thumbnail;
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

/// State machine for jump tracking
enum JumpState { calibrating, ready, inAir, done }

/// Service for measuring broad jump distance using MediaPipe pose detection
/// Based on toe-to-toe horizontal distance tracking
class BroadJumpService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  // Real-time processing state
  bool _isProcessing = false;
  bool _isInitialized = false;
  
  // Frame throttling for performance (process every Nth frame)
  // Similar to MediaPipe's frame skipping for real-time processing
  int _frameSkipCounter = 0;
  static const int _frameSkipInterval = 2; // Process every 3rd frame (~10 FPS from 30 FPS camera)
  
  // Baseline tracking
  List<double> _baselineHeadY = [];
  List<double> _baselineHeelY = [];
  List<double> _baselineToeX = [];
  
  // Jump tracking
  JumpState _state = JumpState.calibrating;
  double? _heightPixels;
  double? _baselineHeadYMean;
  double? _baselineHeelYMean;
  double? _baselineToeXMean;
  double? _takeoffToeX;
  double? _landingToeX;
  int? _takeoffFrame;
  double? _jumpDistanceM;
  int _frameIdx = 0;
  static const int _baselineFrames = 25;
  
  // Landing detection
  List<double> _recentToePositions = [];
  static const int _stabilityWindow = 12;
  static const int _minAirtimeFrames = 15;
  
  // Callback for result
  Function(BroadJumpResult)? _onResult;
  // Callback for live state updates (for UI feedback)
  Function(JumpState, String)? _onStateUpdate;
  double? _userHeightCm;

  /// Measure broad jump distance from a video file
  /// 
  /// [userHeightCm] - User's height in centimeters, retrieved from user profile
  /// This matches the Python implementation logic exactly:
  /// - Progressive landing margin based on frames_in_air
  /// - Absolute 20 pixels threshold for toe stability
  /// - Same baseline calibration, takeoff detection, and distance calculation
  Future<BroadJumpResult> measureBroadJumpFromVideo(
    String videoPath,
    double userHeightCm, // Height from user profile
  ) async {
    // Baseline tracking
    List<double> baselineHeadY = [];
    List<double> baselineHeelY = [];
    List<double> baselineToeX = [];
    
    // Jump tracking
    JumpState state = JumpState.calibrating;
    double? heightPixels;
    double? baselineHeadYMean;
    double? baselineHeelYMean;
    double? baselineToeXMean;
    double? takeoffToeX;
    double? landingToeX;
    int? takeoffFrame;
    double? jumpDistanceM;
    
    // Landing detection
    List<double> recentToePositions = [];
    const int stabilityWindow = 12;
    const int minAirtimeFrames = 15;
    
    int frameIdx = 0;
    const int baselineFrames = 25;

    try {
      // Extract frames from video
      final frames = await _extractFramesFromVideo(videoPath, maxFrames: 200);
      
      if (frames.isEmpty) {
        return BroadJumpResult(
          success: false,
          errorMessage: 'Failed to extract frames from video',
        );
      }

      debugPrint('📹 Extracted ${frames.length} frames for broad jump analysis');

      // Process each frame
      for (int i = 0; i < frames.length; i++) {
        try {
          final inputImage = InputImage.fromFilePath(frames[i]);
          final poses = await _poseDetector.processImage(inputImage);

          if (poses.isNotEmpty) {
            final pose = poses.first;
            
            // Get landmarks
            final nose = pose.landmarks[PoseLandmarkType.nose];
            final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
            final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
            final leftToe = pose.landmarks[PoseLandmarkType.leftFootIndex];
            final rightToe = pose.landmarks[PoseLandmarkType.rightFootIndex];
            
            // Check visibility
            if (nose != null && leftHeel != null && rightHeel != null &&
                leftToe != null && rightToe != null &&
                nose.likelihood > 0.5 && leftHeel.likelihood > 0.5 &&
                rightHeel.likelihood > 0.5 && leftToe.likelihood > 0.5 &&
                rightToe.likelihood > 0.5) {
              
              // Calculate positions (note: Y increases downward in images)
              double headY = nose.y;
              double heelY = (leftHeel.y + rightHeel.y) / 2.0;
              double toeX = max(leftToe.x, rightToe.x); // Furthest forward toe
              
              // ---------- PHASE 1: BASELINE CALIBRATION ----------
              if (frameIdx < baselineFrames) {
                baselineHeadY.add(headY);
                baselineHeelY.add(heelY);
                baselineToeX.add(toeX);
                state = JumpState.calibrating;
              } else if (heightPixels == null) {
                // Calculate baseline averages
                baselineHeadYMean = _average(baselineHeadY);
                baselineHeelYMean = _average(baselineHeelY);
                baselineToeXMean = _average(baselineToeX);
                
                heightPixels = (baselineHeadYMean - baselineHeelYMean).abs();
                takeoffToeX = baselineToeXMean; // Use baseline toe position
                
                debugPrint('📊 Baseline calibration complete:');
                debugPrint('  Head Y: ${baselineHeadYMean?.toStringAsFixed(3)}');
                debugPrint('  Heel Y: ${baselineHeelYMean?.toStringAsFixed(3)}');
                debugPrint('  Toe X: ${baselineToeXMean?.toStringAsFixed(3)}');
                debugPrint('  Height in pixels: ${heightPixels.toStringAsFixed(2)}');
                
                state = JumpState.ready;
              }
              
              // ---------- PHASE 2: STATE MACHINE ----------
              if (heightPixels != null && baselineHeelYMean != null && state == JumpState.ready) {
                // Detect takeoff (heel lifts >12% of body height)
                double liftThreshold = 0.03 * heightPixels; // changed to 0.03 from 0.12
                
                if ((baselineHeelYMean - heelY) > liftThreshold) {
                  state = JumpState.inAir;
                  takeoffFrame = frameIdx;
                  debugPrint('✈️ Takeoff detected at frame $frameIdx');
                  debugPrint('  Using baseline toe X: ${takeoffToeX?.toStringAsFixed(3)}');
                }
              } else if (state == JumpState.inAir && takeoffFrame != null && baselineHeelYMean != null) {
                int framesInAir = frameIdx - takeoffFrame;
                
                if (framesInAir >= minAirtimeFrames) {
                  // Track recent toe positions for stability
                  recentToePositions.add(toeX);
                  if (recentToePositions.length > stabilityWindow) {
                    recentToePositions.removeAt(0);
                  }
                  
                  // Progressive landing margin based on frames_in_air (matching Python logic)
                  double landMargin;
                  if (framesInAir < 20) {
                    landMargin = 0.03 * heightPixels!; // strict: within 3%
                  } else if (framesInAir < 35) {
                    landMargin = 0.05 * heightPixels!; // within 5%
                  } else if (framesInAir < 50) {
                    landMargin = 0.08 * heightPixels!; // within 8%
                  } else {
                    landMargin = 0.12 * heightPixels!; // very lenient: within 12%
                  }
                  
                  bool heelsAtBaseline = (heelY - baselineHeelYMean).abs() < landMargin;
                  
                  // Toe stability check - using absolute 20 pixels threshold (matching Python)
                  bool toesStable = false;
                  if (recentToePositions.length == stabilityWindow) {
                    double maxToe = recentToePositions.reduce(max);
                    double minToe = recentToePositions.reduce(min);
                    double toeVariance = maxToe - minToe;
                    toesStable = toeVariance < 20.0; // 20 pixels absolute (matching Python)
                  }
                  
                  if (heelsAtBaseline && toesStable) {
                    state = JumpState.done;
                    landingToeX = toeX;
                    
                    // Calculate jump distance
                    double pixelJump = (landingToeX - takeoffToeX!).abs();
                    double userHeightM = userHeightCm / 100.0;
                    jumpDistanceM = (pixelJump * userHeightM) / heightPixels!;
                    
                    debugPrint('🎯 Landing detected at frame $frameIdx');
                    debugPrint('  Landing toe X: ${landingToeX.toStringAsFixed(3)}');
                    debugPrint('  Pixel jump: ${pixelJump.toStringAsFixed(2)}');
                    debugPrint('  Jump distance: ${jumpDistanceM.toStringAsFixed(3)} m');
                    
                    break; // Stop processing
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing frame $i: $e');
        }
        
        frameIdx++;
      }

      // Clean up temporary frame files
      for (final framePath in frames) {
        try {
          await File(framePath).delete();
        } catch (e) {
          debugPrint('Failed to delete temp frame: $e');
        }
      }

      // Check if jump was completed
      if (state != JumpState.done || jumpDistanceM == null) {
        String errorMsg = 'Jump not detected.';
        if (state == JumpState.calibrating) {
          errorMsg = 'Not enough baseline frames. Stand still for first 2 seconds.';
        } else if (state == JumpState.ready) {
          errorMsg = 'No takeoff detected. Make sure to jump clearly.';
        } else if (state == JumpState.inAir) {
          errorMsg = 'Landing not detected. Stay still after landing for 1 second.';
        }
        
        return BroadJumpResult(
          success: false,
          errorMessage: errorMsg,
          framesProcessed: frames.length,
        );
      }

      // Determine performance rating
      final rating = _getPerformanceRating(jumpDistanceM);

      debugPrint('✅ Broad jump measured: ${jumpDistanceM.toStringAsFixed(2)} m');
      debugPrint('⭐ Rating: $rating');

      return BroadJumpResult(
        success: true,
        jumpDistanceM: jumpDistanceM,
        jumpDistanceCm: jumpDistanceM * 100,
        rating: rating,
        framesProcessed: frames.length,
      );

    } catch (e) {
      debugPrint('❌ Broad jump measurement error: $e');
      return BroadJumpResult(
        success: false,
        errorMessage: 'Error measuring broad jump: $e',
      );
    }
  }

  /// Calculate average of a list
  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Get performance rating based on distance
  String _getPerformanceRating(double distanceM) {
    // General standards (can be adjusted by age/gender)
    if (distanceM >= 2.5) return 'excellent';
    if (distanceM >= 2.0) return 'good';
    if (distanceM >= 1.5) return 'average';
    return 'needs_improvement';
  }

  /// Get human-readable rating text
  String getPerformanceRatingText(String rating) {
    switch (rating) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'average':
        return 'Average';
      case 'needs_improvement':
        return 'Needs Improvement';
      default:
        return 'Average';
    }
  }

  /// Extract frames from video at regular intervals
  Future<List<String>> _extractFramesFromVideo(String videoPath, {int maxFrames = 200}) async {
    List<String> framePaths = [];
    final tempDir = await getTemporaryDirectory();

    try {
      // Extract frames at intervals (every 100ms)
      for (int i = 0; i < maxFrames; i++) {
        final timeMs = (i * 100); // Extract frame every 100ms
        
        final uint8list = await video_thumbnail.VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: video_thumbnail.ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 75,
        );

        if (uint8list != null) {
          final framePath = '${tempDir.path}/broadjump_frame_$i.jpg';
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

  /// Initialize real-time processing (similar to MediaPipe's live video processing)
  /// 
  /// This method sets up the service to process frames from a live camera feed,
  /// similar to how Python MediaPipe processes video frames in real-time.
  /// 
  /// [userHeightCm] - User's height in centimeters, retrieved from user profile
  /// This matches the Python implementation logic exactly:
  /// - Progressive landing margin based on frames_in_air
  /// - Absolute 20 pixels threshold for toe stability
  /// - Same baseline calibration, takeoff detection, and distance calculation
  /// 
  /// Usage:
  /// ```dart
  /// service.initializeRealTime(
  ///   userHeightCm: user.height, // From user profile
  ///   onResult: (result) => print('Jump distance: ${result.jumpDistanceM}'),
  ///   onStateUpdate: (state, message) => updateUI(state, message),
  /// );
  /// 
  /// // Then process frames from camera stream:
  /// cameraController.startImageStream((image) {
  ///   service.processFrame(image); // Processes each frame like MediaPipe
  /// });
  /// ```
  void initializeRealTime({
    required double userHeightCm, // Height from user profile
    required Function(BroadJumpResult) onResult,
    Function(JumpState, String)? onStateUpdate,
  }) {
    _userHeightCm = userHeightCm;
    _onResult = onResult;
    _onStateUpdate = onStateUpdate;
    _resetState();
    _isInitialized = true;
    debugPrint('🎬 Real-time broad jump processing initialized (MediaPipe-style)');
    _notifyStateUpdate(JumpState.calibrating, 'Stand still for calibration...');
  }
  
  /// Notify state update to UI
  void _notifyStateUpdate(JumpState state, String message) {
    if (_onStateUpdate != null) {
      _onStateUpdate!(state, message);
    }
  }

  /// Reset processing state
  void _resetState() {
    _isProcessing = false;
    _frameSkipCounter = 0;
    _baselineHeadY.clear();
    _baselineHeelY.clear();
    _baselineToeX.clear();
    _state = JumpState.calibrating;
    _heightPixels = null;
    _baselineHeadYMean = null;
    _baselineHeelYMean = null;
    _baselineToeXMean = null;
    _takeoffToeX = null;
    _landingToeX = null;
    _takeoffFrame = null;
    _jumpDistanceM = null;
    _frameIdx = 0;
    _recentToePositions.clear();
  }

  /// Process a camera frame in real-time (similar to MediaPipe live processing)
  /// 
  /// This method processes frames from a live camera feed, similar to how
  /// Python MediaPipe analyzes video frames in real-time. It uses:
  /// - Frame throttling to maintain ~10 FPS processing rate
  /// - Non-blocking async processing to keep camera stream smooth
  /// - Pose detection on each processed frame
  /// 
  /// Similar to MediaPipe's approach:
  /// ```python
  /// with mp_pose.Pose() as pose:
  ///     for frame in camera.capture_continuous():
  ///         results = pose.process(frame)
  ///         # Process results...
  /// ```
  /// 
  /// In Flutter:
  /// ```dart
  /// cameraController.startImageStream((image) {
  ///     service.processFrame(image); // Like MediaPipe's frame processing
  /// });
  /// ```
  /// 
  /// Uses frame throttling to maintain performance while processing live feed
  Future<void> processFrame(CameraImage image) async {
    if (!_isInitialized || _state == JumpState.done) return;
    
    // Frame throttling: Skip frames to maintain ~10 FPS processing rate
    // This is similar to how MediaPipe optimizes for real-time performance
    _frameSkipCounter++;
    if (_frameSkipCounter < _frameSkipInterval) {
      return; // Skip this frame
    }
    _frameSkipCounter = 0;
    
    // If already processing a frame, skip this one (non-blocking approach)
    if (_isProcessing) {
      return;
    }
    
    _isProcessing = true;
    
    // Process frame asynchronously without blocking the camera stream
    _processFrameAsync(image).catchError((error) {
      debugPrint('⚠️ Error in async frame processing: $error');
      _isProcessing = false;
    });
  }

  /// Internal async frame processing method
  Future<void> _processFrameAsync(CameraImage image) async {
    try {
      // Convert camera image to InputImage
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }
      
      // Detect pose (this is the MLKit pose detection, similar to MediaPipe)
      final poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) {
        _isProcessing = false;
        return;
      }
      
      final pose = poses.first;
      
      // Get landmarks
      final nose = pose.landmarks[PoseLandmarkType.nose];
      final leftHeel = pose.landmarks[PoseLandmarkType.leftHeel];
      final rightHeel = pose.landmarks[PoseLandmarkType.rightHeel];
      final leftToe = pose.landmarks[PoseLandmarkType.leftFootIndex];
      final rightToe = pose.landmarks[PoseLandmarkType.rightFootIndex];
      
      // Check visibility
      if (nose != null && leftHeel != null && rightHeel != null &&
          leftToe != null && rightToe != null &&
          nose.likelihood > 0.5 && leftHeel.likelihood > 0.5 &&
          rightHeel.likelihood > 0.5 && leftToe.likelihood > 0.5 &&
          rightToe.likelihood > 0.5) {
        
        // Calculate positions (note: Y increases downward in images)
        double headY = nose.y;
        double heelY = (leftHeel.y + rightHeel.y) / 2.0;
        double toeX = max(leftToe.x, rightToe.x); // Furthest forward toe
        
        // ---------- PHASE 1: BASELINE CALIBRATION ----------
        if (_frameIdx < _baselineFrames) {
          _baselineHeadY.add(headY);
          _baselineHeelY.add(heelY);
          _baselineToeX.add(toeX);
          _state = JumpState.calibrating;
          
          // Update UI with calibration progress
          int progress = ((_frameIdx / _baselineFrames) * 100).round();
          _notifyStateUpdate(
            JumpState.calibrating,
            'Calibrating... $progress% (${_frameIdx}/$_baselineFrames frames)',
          );
        } else if (_heightPixels == null) {
          // Calculate baseline averages
          _baselineHeadYMean = _average(_baselineHeadY);
          _baselineHeelYMean = _average(_baselineHeelY);
          _baselineToeXMean = _average(_baselineToeX);
          
          if (_baselineHeadYMean != null && _baselineHeelYMean != null) {
            _heightPixels = (_baselineHeadYMean! - _baselineHeelYMean!).abs();
            _takeoffToeX = _baselineToeXMean; // Use baseline toe position
            
            debugPrint('📊 Baseline calibration complete:');
            debugPrint('  Head Y: ${_baselineHeadYMean?.toStringAsFixed(3)}');
            debugPrint('  Heel Y: ${_baselineHeelYMean?.toStringAsFixed(3)}');
            debugPrint('  Toe X: ${_baselineToeXMean?.toStringAsFixed(3)}');
            debugPrint('  Height in pixels: ${_heightPixels?.toStringAsFixed(2)}');
            
            _state = JumpState.ready;
            _notifyStateUpdate(JumpState.ready, 'Ready! Jump forward now!');
          }
        }
        
        // ---------- PHASE 2: STATE MACHINE ----------
        if (_heightPixels != null && _baselineHeelYMean != null && _state == JumpState.ready) {
          // Detect takeoff (heel lifts >3% of body height)
          final heightPixels = _heightPixels!;
          final baselineHeelYMean = _baselineHeelYMean!;
          double liftThreshold = 0.03 * heightPixels;
          
          if ((baselineHeelYMean - heelY) > liftThreshold) {
            _state = JumpState.inAir;
            _takeoffFrame = _frameIdx;
            debugPrint('✈️ Takeoff detected at frame $_frameIdx');
            debugPrint('  Using baseline toe X: ${_takeoffToeX?.toStringAsFixed(3)}');
            _notifyStateUpdate(JumpState.inAir, '✈️ In Air! Tracking jump...');
          }
        } else if (_state == JumpState.inAir && _takeoffFrame != null && _baselineHeelYMean != null) {
          final takeoffFrame = _takeoffFrame!;
          final baselineHeelYMean = _baselineHeelYMean!;
          final heightPixels = _heightPixels!;
          int framesInAir = _frameIdx - takeoffFrame;
          
          if (framesInAir >= _minAirtimeFrames) {
            // Track recent toe positions for stability
            _recentToePositions.add(toeX);
            if (_recentToePositions.length > _stabilityWindow) {
              _recentToePositions.removeAt(0);
            }
            
            // Progressive landing margin based on frames_in_air (matching Python logic)
            double landMargin;
            if (framesInAir < 20) {
              landMargin = 0.03 * heightPixels; // strict: within 3%
            } else if (framesInAir < 35) {
              landMargin = 0.05 * heightPixels; // within 5%
            } else if (framesInAir < 50) {
              landMargin = 0.08 * heightPixels; // within 8%
            } else {
              landMargin = 0.12 * heightPixels; // very lenient: within 12%
            }
            
            bool heelsAtBaseline = (heelY - baselineHeelYMean).abs() < landMargin;
            
            // Toe stability check - using absolute 20 pixels threshold (matching Python)
            bool toesStable = false;
            if (_recentToePositions.length == _stabilityWindow) {
              double maxToe = _recentToePositions.reduce(max);
              double minToe = _recentToePositions.reduce(min);
              double toeVariance = maxToe - minToe;
              toesStable = toeVariance < 20.0; // 20 pixels absolute (matching Python)
            }
            
            if (heelsAtBaseline && toesStable) {
              _state = JumpState.done;
              _landingToeX = toeX;
              
              // Calculate jump distance
              final landingToeX = _landingToeX!;
              final takeoffToeX = _takeoffToeX!;
              final userHeightCm = _userHeightCm!;
              double pixelJump = (landingToeX - takeoffToeX).abs();
              double userHeightM = userHeightCm / 100.0;
              _jumpDistanceM = (pixelJump * userHeightM) / heightPixels;
              
              final jumpDistanceM = _jumpDistanceM!;
              
              debugPrint('🎯 Landing detected at frame $_frameIdx');
              debugPrint('  Landing toe X: ${landingToeX.toStringAsFixed(3)}');
              debugPrint('  Pixel jump: ${pixelJump.toStringAsFixed(2)}');
              debugPrint('  Jump distance: ${jumpDistanceM.toStringAsFixed(3)} m');
              
              // Determine performance rating
              final rating = _getPerformanceRating(jumpDistanceM);
              
              debugPrint('✅ Broad jump measured: ${jumpDistanceM.toStringAsFixed(2)} m');
              debugPrint('⭐ Rating: $rating');
              
              // Notify landing detected
              _notifyStateUpdate(
                JumpState.done,
                '✅ Landing detected! Distance: ${jumpDistanceM.toStringAsFixed(2)}m',
              );
              
              // Return result via callback
              if (_onResult != null) {
                _onResult!(BroadJumpResult(
                  success: true,
                  jumpDistanceM: jumpDistanceM,
                  jumpDistanceCm: jumpDistanceM * 100,
                  rating: rating,
                  framesProcessed: _frameIdx + 1,
                ));
              }
            } else {
              // Still in air, update status
              _notifyStateUpdate(
                JumpState.inAir,
                '✈️ In Air... Waiting for landing',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error processing frame: $e');
    } finally {
      _isProcessing = false;
      _frameIdx++;
    }
  }

  /// Convert CameraImage to InputImage for MLKit (similar to MediaPipe's image conversion)
  /// Handles different camera formats (YUV420, NV21, etc.)
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        debugPrint('⚠️ Unsupported camera format: ${image.format.raw}');
        return null;
      }
      
      // Handle different image formats
      if (image.planes.length != 1) {
        // Multi-plane format (YUV420, etc.)
        final plane = image.planes[0];
        final bytes = plane.bytes;
        
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: format,
            bytesPerRow: plane.bytesPerRow,
          ),
        );
      } else {
        // Single plane format
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
      }
    } catch (e) {
      debugPrint('❌ Error converting camera image: $e');
      return null;
    }
  }

  /// Stop real-time processing and return current result or error
  BroadJumpResult stopProcessing() {
    if (_state == JumpState.done && _jumpDistanceM != null) {
      final rating = _getPerformanceRating(_jumpDistanceM!);
      return BroadJumpResult(
        success: true,
        jumpDistanceM: _jumpDistanceM,
        jumpDistanceCm: _jumpDistanceM! * 100,
        rating: rating,
        framesProcessed: _frameIdx,
      );
    }
    
    String errorMsg = 'Jump not detected.';
    if (_state == JumpState.calibrating) {
      errorMsg = 'Not enough baseline frames. Stand still for first 2 seconds.';
    } else if (_state == JumpState.ready) {
      errorMsg = 'No takeoff detected. Make sure to jump clearly.';
    } else if (_state == JumpState.inAir) {
      errorMsg = 'Landing not detected. Stay still after landing for 1 second.';
    }
    
    return BroadJumpResult(
      success: false,
      errorMessage: errorMsg,
      framesProcessed: _frameIdx,
    );
  }

  /// Dispose resources
  void dispose() {
    _poseDetector.close();
    _resetState();
  }
}

/// Result of broad jump measurement
class BroadJumpResult {
  final bool success;
  final double? jumpDistanceM;
  final double? jumpDistanceCm;
  final String? rating;
  final String? errorMessage;
  final int? framesProcessed;

  BroadJumpResult({
    required this.success,
    this.jumpDistanceM,
    this.jumpDistanceCm,
    this.rating,
    this.errorMessage,
    this.framesProcessed,
  });

  /// Get formatted distance for display
  String get formattedDistanceM {
    if (jumpDistanceM == null) return 'N/A';
    return '${jumpDistanceM!.toStringAsFixed(2)} m';
  }

  String get formattedDistanceCm {
    if (jumpDistanceCm == null) return 'N/A';
    return '${jumpDistanceCm!.toStringAsFixed(1)} cm';
  }

  String get formattedDistanceInches {
    if (jumpDistanceCm == null) return 'N/A';
    double inches = jumpDistanceCm! / 2.54;
    return '${inches.toStringAsFixed(1)} inches';
  }
}

