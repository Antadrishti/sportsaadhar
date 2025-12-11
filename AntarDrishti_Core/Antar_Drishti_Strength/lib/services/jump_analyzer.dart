import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/jump_result.dart';
import '../utils/constants.dart';
import 'pose_detector_service.dart';

/// Core jump analysis engine - ported from Python standing_vertical_jump.py
class JumpAnalyzer {
  final PoseDetectorService _poseDetector = PoseDetectorService();
  
  /// Analyze a video file to detect vertical jump height
  /// [videoPath] - Path to the video file
  /// [knownHeightCm] - Person's height in centimeters
  /// [fps] - Frames per second of the video
  /// [onProgress] - Optional callback for progress updates (0.0 to 1.0)
  Future<JumpResult> analyzeVideo({
    required String videoPath,
    required double knownHeightCm,
    required double fps,
    required List<InputImage> frames,
    required int imageHeight,
    required int imageWidth,
    void Function(double progress, String status)? onProgress,
  }) async {
    await _poseDetector.initialize();
    
    final knownHeightM = knownHeightCm / 100.0;
    final List<double?> hipYs = [];
    final List<double?> ankleMeans = [];
    final List<double> timestamps = [];
    final List<double?> scales = [];
    
    onProgress?.call(0.1, 'Processing frames...');
    
    // Process each frame
    for (int i = 0; i < frames.length; i++) {
      final t = (i + 1) / fps;
      timestamps.add(t);
      
      try {
        final poses = await _poseDetector.processImage(frames[i]);
        final pose = poses.isNotEmpty ? poses.first : null;
        
        if (pose != null) {
          // Get knee Y (mean of left and right) - using knee instead of hip for better detection
          final hipY = PoseDetectorService.getMeanLandmarkY(
            pose,
            PoseLandmarkType.leftKnee,
            PoseLandmarkType.rightKnee,
          );
          hipYs.add(hipY);
          
          // Get ankle mean Y
          final ankleMean = PoseDetectorService.getMeanLandmarkY(
            pose,
            PoseLandmarkType.leftAnkle,
            PoseLandmarkType.rightAnkle,
            minLikelihood: 0.05,
          );
          ankleMeans.add(ankleMean);
          
          // Compute scale
          final scale = PoseDetectorService.computeScaleFromHeight(pose, knownHeightM);
          scales.add(scale);
        } else {
          hipYs.add(null);
          ankleMeans.add(null);
          scales.add(null);
        }
      } catch (e) {
        hipYs.add(null);
        ankleMeans.add(null);
        scales.add(null);
      }
      
      // Update progress
      if (i % 5 == 0) {
        onProgress?.call(0.1 + 0.6 * (i / frames.length), 'Analyzing frame ${i + 1}/${frames.length}');
      }
    }
    
    onProgress?.call(0.75, 'Calculating jump height...');
    
    // Calculate median scale from valid scales
    final validScales = scales.whereType<double>().toList();
    final double? scale = validScales.isNotEmpty ? _median(validScales) : null;
    
    // Calculate baseline from first ~1.2 seconds
    final baselineFrameCount = min(frames.length, max(1, (1.2 * fps).toInt()));
    final baselineHipValues = hipYs.take(baselineFrameCount).whereType<double>().toList();
    
    double? baselineHip = baselineHipValues.isNotEmpty 
        ? _median(baselineHipValues)
        : null;
    
    // If no baseline from first frames, use all valid hips
    if (baselineHip == null) {
      final allValidHips = hipYs.whereType<double>().toList();
      baselineHip = allValidHips.isNotEmpty ? _median(allValidHips) : null;
    }
    
    // Check if we have valid knee landmarks
    final validHips = hipYs.whereType<double>().toList();
    if (validHips.isEmpty) {
      await _poseDetector.dispose();
      return JumpResult.error('no_knee_landmarks');
    }
    
    // Find peak hip position (lowest Y value = highest point in image coords)
    final peakHipPx = validHips.reduce(min);
    
    // Calculate vertical displacement in pixels
    final verticalPx = (baselineHip ?? 0) - peakHipPx;
    
    // Convert to meters
    final double? verticalM = scale != null ? max(0.0, verticalPx * scale) : null;
    
    onProgress?.call(0.85, 'Detecting takeoff and landing...');
    
    // Detect takeoff and landing
    final baselineAnkleValues = ankleMeans.take(baselineFrameCount).whereType<double>().toList();
    final double? baselineAnkle = baselineAnkleValues.isNotEmpty 
        ? _median(baselineAnkleValues) 
        : null;
    
    final takeoffLanding = _detectTakeoffLanding(
      ankleMeans,
      timestamps,
      baselineAnkle,
      imageHeight.toDouble(),
      fps,
    );
    
    final int? takeoffIdx = takeoffLanding.$1;
    final int? landingIdx = takeoffLanding.$2;
    final double? flightTime = takeoffLanding.$3;
    
    // Calculate flight height using physics
    final double? flightHeight = flightTime != null 
        ? (AppConstants.g * (flightTime * flightTime)) / 8.0 
        : null;
    
    onProgress?.call(0.95, 'Computing confidence...');
    
    // Calculate confidence
    double confidence = 0.5;
    if (verticalM != null && verticalM > 0.01) confidence += 0.2;
    if (flightHeight != null) {
      final diff = ((verticalM ?? 0) - flightHeight).abs();
      final relErr = diff / max(1e-6, max(verticalM ?? 1e-6, flightHeight));
      confidence += relErr < 0.25 ? 0.25 : -0.05;
    }
    if (scale == null) confidence -= 0.25;
    confidence = confidence.clamp(0.0, 1.0);
    
    // Collect flags
    final List<String> flags = [];
    if (scale == null) flags.add('no_scale_detected');
    final validAnkleCount = ankleMeans.whereType<double>().length;
    if (validAnkleCount < max(3, (0.2 * ankleMeans.length).toInt())) {
      flags.add('ankle_landmarks_sparse');
    }
    if (takeoffIdx == null) flags.add('no_takeoff_detected');
    if (landingIdx == null) flags.add('no_landing_detected');
    
    await _poseDetector.dispose();
    
    onProgress?.call(1.0, 'Analysis complete!');
    
    return JumpResult(
      method: 'hip_displacement',
      verticalM: verticalM != null ? double.parse(verticalM.toStringAsFixed(3)) : null,
      verticalPx: double.parse(verticalPx.toStringAsFixed(2)),
      scaleMPerPx: scale != null ? double.parse(scale.toStringAsFixed(6)) : null,
      baselineHipPx: double.parse((baselineHip ?? 0).toStringAsFixed(2)),
      peakHipPx: double.parse(peakHipPx.toStringAsFixed(2)),
      flightTimeS: flightTime != null ? double.parse(flightTime.toStringAsFixed(3)) : null,
      flightHeightM: flightHeight != null ? double.parse(flightHeight.toStringAsFixed(3)) : null,
      confidence: double.parse(confidence.toStringAsFixed(3)),
      baselineFrames: baselineFrameCount,
      takeoffIdx: takeoffIdx,
      landingIdx: landingIdx,
      totalFrames: frames.length,
      flags: flags,
    );
  }
  
  /// Detect takeoff and landing frames based on ankle movement
  /// Returns (takeoffIdx, landingIdx, flightTime) or nulls
  (int?, int?, double?) _detectTakeoffLanding(
    List<double?> ankleMeans,
    List<double> timestamps,
    double? baselineAnkle,
    double imageHeight,
    double fps,
  ) {
    if (baselineAnkle == null) return (null, null, null);
    
    final riseThreshPx = max(AppConstants.minRiseThresholdPx, AppConstants.riseThresholdFactor * imageHeight);
    final n = ankleMeans.length;
    int? takeoff;
    int? landing;
    
    // Find takeoff
    for (int i = 0; i < n - 5; i++) {
      final ankle = ankleMeans[i];
      if (ankle == null) continue;
      
      // Y decreases when going up (image coordinates)
      if (ankle < baselineAnkle - riseThreshPx) {
        // Check window of 5 frames
        int validCount = 0;
        bool allAboveThreshold = true;
        
        for (int j = i; j < min(i + 5, n); j++) {
          final windowAnkle = ankleMeans[j];
          if (windowAnkle != null) {
            validCount++;
            if (windowAnkle >= baselineAnkle - (riseThreshPx * 0.6)) {
              allAboveThreshold = false;
              break;
            }
          }
        }
        
        if (validCount >= 3 && allAboveThreshold) {
          takeoff = i;
          break;
        }
      }
    }
    
    if (takeoff == null) return (null, null, null);
    
    // Find landing
    for (int j = takeoff + 3; j < n - 1; j++) {
      final ankle = ankleMeans[j];
      if (ankle == null) continue;
      
      if (ankle >= baselineAnkle - (riseThreshPx * 0.45)) {
        landing = j;
        break;
      }
    }
    
    if (landing == null) return (takeoff, null, null);
    
    final flightTime = timestamps[landing] - timestamps[takeoff];
    return (takeoff, landing, flightTime);
  }
  
  /// Calculate median of a list of doubles
  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[mid];
    }
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
