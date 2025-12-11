import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/physical_test.dart';
import '../../core/services/shuttle_run_service.dart';
import 'dart:async';

/// Setup screen for shuttle run - calibrate GPS and check stationary
class ShuttleRunSetupScreen extends StatefulWidget {
  final PhysicalTest test;

  const ShuttleRunSetupScreen({
    super.key,
    required this.test,
  });

  @override
  State<ShuttleRunSetupScreen> createState() => _ShuttleRunSetupScreenState();
}

class _ShuttleRunSetupScreenState extends State<ShuttleRunSetupScreen> {
  final ShuttleRunService _shuttleRunService = ShuttleRunService();
  
  bool _isInitializing = true;
  bool _gpsReady = false;
  int _countdown = 0;
  bool _testStarting = false;
  
  double? _gpsAccuracy;
  String _statusMessage = 'Initializing GPS...';
  Timer? _gpsCheckTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeGPS();
  }

  @override
  void dispose() {
    _gpsCheckTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeGPS() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Requesting location permissions...';
    });

    bool initialized = await _shuttleRunService.initializeGPS();

    if (!mounted) return;

    if (!initialized) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Failed to initialize GPS. Please enable location services.';
      });
      _showErrorDialog('GPS initialization failed', 
          'Please enable location services and grant location permissions.');
      return;
    }

    // Start checking GPS accuracy periodically
    _startGPSAccuracyChecks();
  }

  void _startGPSAccuracyChecks() {
    _gpsCheckTimer?.cancel();
    _gpsCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final result = await _shuttleRunService.checkGPSAccuracy();
      
      if (mounted) {
        setState(() {
          _gpsAccuracy = result.accuracy;
          _gpsReady = result.isAccurate;
          _isInitializing = false;
          _statusMessage = result.message;
        });
      }
    });
  }

  void _startTest() {
    if (!_gpsReady) return;

    setState(() {
      _statusMessage = 'Ready to start!';
    });
    
    // Start countdown directly
    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 3;
      _testStarting = true;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _navigateToTracking();
      }
    });
  }

  /// Calibrate GPS by taking multiple readings and averaging them
  Future<Position> _calibrateGPS() async {
    // Reduced to 3 readings with shorter delay for faster calibration
    const int numReadings = 3;
    const Duration delayBetweenReadings = Duration(milliseconds: 300);
    const int maxAttempts = 5; // Maximum attempts to get good readings
    
    List<Position> readings = [];
    
    if (mounted) {
      setState(() {
        _statusMessage = 'Calibrating GPS...';
      });
    }
    
    int attempts = 0;
    while (readings.length < numReadings && attempts < maxAttempts) {
      attempts++;
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        
        // Only use accurate readings (accuracy < 15m)
        if (position.accuracy < 15.0) {
          readings.add(position);
          debugPrint('📍 Calibration reading ${readings.length}: accuracy=${position.accuracy.toStringAsFixed(1)}m');
          
          if (mounted) {
            setState(() {
              _statusMessage = 'Calibrating GPS... (${readings.length}/$numReadings)';
            });
          }
        } else {
          debugPrint('⚠️ Skipping inaccurate calibration reading: accuracy=${position.accuracy.toStringAsFixed(1)}m');
        }
        
        // Only delay if we need more readings
        if (readings.length < numReadings && attempts < maxAttempts) {
          await Future.delayed(delayBetweenReadings);
        }
      } catch (e) {
        debugPrint('Error getting calibration reading: $e');
        if (attempts < maxAttempts) {
          await Future.delayed(delayBetweenReadings);
        }
      }
    }
    
    if (readings.isEmpty) {
      // Fallback to single reading if calibration failed
      debugPrint('⚠️ Calibration failed, using single reading');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
    }
    
    // If we have at least 2 readings, use them; otherwise use what we have
    if (readings.length >= 2) {
      // Calculate average position
      double avgLat = readings.map((p) => p.latitude).reduce((a, b) => a + b) / readings.length;
      double avgLon = readings.map((p) => p.longitude).reduce((a, b) => a + b) / readings.length;
      double avgAccuracy = readings.map((p) => p.accuracy).reduce((a, b) => a + b) / readings.length;
      
      // Create averaged position (using first reading as template)
      Position averagedPosition = Position(
        latitude: avgLat,
        longitude: avgLon,
        timestamp: DateTime.now(),
        accuracy: avgAccuracy,
        altitude: readings.first.altitude,
        altitudeAccuracy: readings.first.altitudeAccuracy,
        heading: readings.first.heading,
        headingAccuracy: readings.first.headingAccuracy,
        speed: readings.first.speed,
        speedAccuracy: readings.first.speedAccuracy,
      );
      
      debugPrint('✅ GPS calibrated: ${readings.length} readings averaged, accuracy=${avgAccuracy.toStringAsFixed(1)}m');
      return averagedPosition;
    } else {
      // Use single reading if we only have one
      debugPrint('✅ GPS calibrated: using single reading, accuracy=${readings.first.accuracy.toStringAsFixed(1)}m');
      return readings.first;
    }
  }

  void _navigateToTracking() async {
    _gpsCheckTimer?.cancel();
    _countdownTimer?.cancel();

    // Calibrate GPS by taking multiple readings
    Position startPosition = await _calibrateGPS();

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/shuttle-run-tracking',
        arguments: {
          'test': widget.test,
          'startPosition': startPosition,
        },
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGPS();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor() {
    if (_gpsAccuracy == null) return Colors.grey;
    if (_gpsAccuracy! < 5.0) return Colors.green;
    if (_gpsAccuracy! < 10.0) return Colors.lightGreen;
    if (_gpsAccuracy! < 15.0) return Colors.orange;
    return Colors.red;
  }

  IconData _getAccuracyIcon() {
    if (!_gpsReady) return Icons.gps_not_fixed;
    return Icons.gps_fixed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Setup - ${widget.test.name}'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: _testStarting ? null : () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade800),
                            const SizedBox(width: 12),
                            const Text(
                              'Setup Instructions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInstruction('1', 'Find an open outdoor area'),
                        const SizedBox(height: 8),
                        _buildInstruction('2', 'Place markers 10 meters apart'),
                        const SizedBox(height: 8),
                        _buildInstruction('3', 'Stand at start position'),
                        const SizedBox(height: 8),
                        _buildInstruction('4', 'Wait for GPS to be ready'),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 32),

                  // GPS Accuracy indicator
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getAccuracyColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getAccuracyColor(), width: 2),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getAccuracyIcon(),
                          color: _getAccuracyColor(),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getAccuracyColor(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_gpsAccuracy != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Accuracy: ${_gpsAccuracy!.toStringAsFixed(1)} meters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Status indicators
                  _buildStatusItem(
                    'GPS Ready',
                    _gpsReady,
                    _isInitializing,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Countdown overlay
          if (_testStarting && _countdown > 0)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _countdown.toString(),
                      style: const TextStyle(
                        fontSize: 120,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(),
                    ).scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.2, 1.2),
                      duration: 1000.ms,
                      curve: Curves.easeOut,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Get Ready!',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Start button
          if (!_testStarting)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _gpsReady ? _startTest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28D25),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Test',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF2196F3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, bool isComplete, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isComplete
            ? Colors.green.shade50
            : (isLoading ? Colors.blue.shade50 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? Colors.green
              : (isLoading ? Colors.blue : Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.blue.shade700,
              ),
            )
          else
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isComplete ? Colors.green : Colors.grey,
              size: 24,
            ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isComplete ? Colors.green.shade900 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}



