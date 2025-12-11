/// App constants for the vertical jump height measurement
class AppConstants {
  /// Gravitational acceleration in m/s²
  static const double g = 9.81;
  
  /// Maximum recording duration in seconds
  static const int maxRecordingDurationSeconds = 10;
  
  /// Countdown before recording starts in seconds
  static const int countdownSeconds = 3;
  
  /// Minimum allowed height in cm
  static const double minHeightCm = 50;
  
  /// Maximum allowed height in cm
  static const double maxHeightCm = 300;
  
  /// Default height in cm
  static const double defaultHeightCm = 170;
  
  /// Rise threshold factor for takeoff detection
  static const double riseThresholdFactor = 0.008;
  
  /// Minimum rise threshold in pixels
  static const double minRiseThresholdPx = 6;
}
