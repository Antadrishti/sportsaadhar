/// Model representing the result of a vertical jump analysis
class JumpResult {
  /// Analysis method used ("hip_displacement")
  final String method;
  
  /// Vertical jump height in meters (null if calculation failed)
  final double? verticalM;
  
  /// Vertical displacement in pixels
  final double verticalPx;
  
  /// Scale factor: meters per pixel (null if not estimated)
  final double? scaleMPerPx;
  
  /// Baseline hip Y position in pixels
  final double baselineHipPx;
  
  /// Peak (lowest Y value) hip position during jump in pixels
  final double peakHipPx;
  
  /// Flight time in seconds (null if not detected)
  final double? flightTimeS;
  
  /// Jump height calculated from flight time (null if not calculated)
  final double? flightHeightM;
  
  /// Confidence score from 0.0 to 1.0
  final double confidence;
  
  /// Frame information
  final int baselineFrames;
  final int? takeoffIdx;
  final int? landingIdx;
  final int totalFrames;
  
  /// Warning flags
  final List<String> flags;
  
  JumpResult({
    required this.method,
    this.verticalM,
    required this.verticalPx,
    this.scaleMPerPx,
    required this.baselineHipPx,
    required this.peakHipPx,
    this.flightTimeS,
    this.flightHeightM,
    required this.confidence,
    required this.baselineFrames,
    this.takeoffIdx,
    this.landingIdx,
    required this.totalFrames,
    required this.flags,
  });
  
  /// Jump height in centimeters
  double? get verticalCm => verticalM != null ? verticalM! * 100 : null;
  
  /// Jump height in inches
  double? get verticalInches => verticalM != null ? verticalM! * 39.3701 : null;
  
  /// Confidence level as a string
  String get confidenceLevel {
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.4) return 'Medium';
    return 'Low';
  }
  
  /// Check if the analysis was successful
  bool get isValid => verticalM != null && verticalM! > 0;
  
  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'method': method,
    'vertical_m': verticalM,
    'vertical_px': verticalPx,
    'scale_m_per_px': scaleMPerPx,
    'baseline_hip_px': baselineHipPx,
    'peak_hip_px': peakHipPx,
    'flight_time_s': flightTimeS,
    'flight_height_m': flightHeightM,
    'confidence': confidence,
    'frames': {
      'baseline_frames': baselineFrames,
      'takeoff_idx': takeoffIdx,
      'landing_idx': landingIdx,
      'total_frames': totalFrames,
    },
    'flags': flags,
  };
  
  /// Create from JSON map
  factory JumpResult.fromJson(Map<String, dynamic> json) {
    final frames = json['frames'] as Map<String, dynamic>;
    return JumpResult(
      method: json['method'] as String,
      verticalM: json['vertical_m'] as double?,
      verticalPx: (json['vertical_px'] as num).toDouble(),
      scaleMPerPx: json['scale_m_per_px'] as double?,
      baselineHipPx: (json['baseline_hip_px'] as num).toDouble(),
      peakHipPx: (json['peak_hip_px'] as num).toDouble(),
      flightTimeS: json['flight_time_s'] as double?,
      flightHeightM: json['flight_height_m'] as double?,
      confidence: (json['confidence'] as num).toDouble(),
      baselineFrames: frames['baseline_frames'] as int,
      takeoffIdx: frames['takeoff_idx'] as int?,
      landingIdx: frames['landing_idx'] as int?,
      totalFrames: frames['total_frames'] as int,
      flags: List<String>.from(json['flags'] as List),
    );
  }
  
  /// Create an error result
  factory JumpResult.error(String errorMessage) => JumpResult(
    method: 'error',
    verticalPx: 0,
    baselineHipPx: 0,
    peakHipPx: 0,
    confidence: 0,
    baselineFrames: 0,
    totalFrames: 0,
    flags: [errorMessage],
  );
}
