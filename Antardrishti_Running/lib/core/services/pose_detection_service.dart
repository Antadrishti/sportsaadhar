import 'dart:io';

/// Result returned by [PoseDetectionService] once a video has been analyzed.
class PoseAnalysisResult {
  final Map<String, dynamic> metrics;
  final bool isValid;
  final Map<String, dynamic>? debugData;

  const PoseAnalysisResult({
    required this.metrics,
    required this.isValid,
    this.debugData,
  });

  /// Fallback data so engineers integrating MediaPipe/TFLite can see the shape
  /// of the expected payload before hooking up the real model.
  factory PoseAnalysisResult.placeholder({required String testName}) {
    return PoseAnalysisResult(
      metrics: {
        'test_name': testName,
        'pose_service': 'stub',
        'score': 0,
        'notes': 'Replace PoseDetectionService.analyzeVideo with MediaPipe/TFLite.'
      },
      isValid: true,
      debugData: const {
        'landmarks': 'not_computed',
      },
    );
  }
}

/// Central place to integrate on-device ML (MediaPipe, TFLite, etc.).
///
/// Replace the contents of [analyzeVideo] with the concrete pipeline that
/// loads the model, runs inference frame-by-frame and returns metrics that
/// the rest of the app can store/sync.
class PoseDetectionService {
  bool _initialized = false;

  /// Perform any heavy setup (loading models, allocating interpreters, etc.).
  Future<void> initialize() async {
    if (_initialized) return;

    // TODO: Load TFLite model / MediaPipe graph here.
    _initialized = true;
  }

  Future<PoseAnalysisResult> analyzeVideo({
    required File videoFile,
    required String testName,
  }) async {
    await initialize();

    // TODO: Replace with real keypoint detection + metric extraction.
    // The stub keeps API/DB flows working until the ML code is ready.
    return PoseAnalysisResult.placeholder(testName: testName);
  }
}
