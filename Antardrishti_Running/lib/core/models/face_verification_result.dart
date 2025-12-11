/// Result returned by [FaceVerificationService] after face matching verification.
/// 
/// This represents the outcome of 1:1 face matching between a reference image
/// and faces detected in a video.
class FaceVerificationResult {
  /// Whether the face in the video matches the reference image.
  final bool isMatch;

  /// Confidence score between 0.0 and 1.0 indicating match certainty.
  /// Higher values indicate stronger confidence in the match.
  final double confidenceScore;

  /// Threshold used for determining match (default: 0.6).
  /// Faces with confidence >= threshold are considered matches.
  final double threshold;

  /// Number of faces detected in the video.
  final int facesDetected;

  /// Number of frames processed from the video.
  final int framesProcessed;

  /// Error message if verification failed (null if successful).
  final String? errorMessage;

  /// Debug data including landmarks, timestamps, etc.
  final Map<String, dynamic>? debugData;

  const FaceVerificationResult({
    required this.isMatch,
    required this.confidenceScore,
    this.threshold = 0.6,
    this.facesDetected = 0,
    this.framesProcessed = 0,
    this.errorMessage,
    this.debugData,
  });

  /// Creates a result indicating a successful match.
  factory FaceVerificationResult.match({
    required double confidenceScore,
    double threshold = 0.6,
    int facesDetected = 1,
    int framesProcessed = 1,
    Map<String, dynamic>? debugData,
  }) {
    return FaceVerificationResult(
      isMatch: true,
      confidenceScore: confidenceScore,
      threshold: threshold,
      facesDetected: facesDetected,
      framesProcessed: framesProcessed,
      debugData: debugData,
    );
  }

  /// Creates a result indicating no match found.
  factory FaceVerificationResult.noMatch({
    required double confidenceScore,
    double threshold = 0.6,
    int facesDetected = 0,
    int framesProcessed = 1,
    Map<String, dynamic>? debugData,
  }) {
    return FaceVerificationResult(
      isMatch: false,
      confidenceScore: confidenceScore,
      threshold: threshold,
      facesDetected: facesDetected,
      framesProcessed: framesProcessed,
      debugData: debugData,
    );
  }

  /// Creates a result indicating an error occurred.
  factory FaceVerificationResult.error({
    required String errorMessage,
    Map<String, dynamic>? debugData,
  }) {
    return FaceVerificationResult(
      isMatch: false,
      confidenceScore: 0.0,
      errorMessage: errorMessage,
      debugData: debugData,
    );
  }

  /// Whether the verification was successful (no errors).
  bool get isSuccessful => errorMessage == null;

  /// Human-readable verification status message.
  String get statusMessage {
    if (!isSuccessful) {
      return 'Verification failed: $errorMessage';
    }
    if (isMatch) {
      return 'Face verified successfully (${(confidenceScore * 100).toStringAsFixed(1)}% confidence)';
    }
    return 'Face verification failed (${(confidenceScore * 100).toStringAsFixed(1)}% confidence)';
  }
}





