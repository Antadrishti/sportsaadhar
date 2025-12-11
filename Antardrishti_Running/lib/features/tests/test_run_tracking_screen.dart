import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/physical_test.dart';
import '../../core/models/test_result_model.dart';

class TestRunTrackingScreen extends StatefulWidget {
  final PhysicalTest test;
  final double targetDistance; // in meters

  const TestRunTrackingScreen({
    super.key,
    required this.test,
    required this.targetDistance,
  });

  @override
  State<TestRunTrackingScreen> createState() => _TestRunTrackingScreenState();
}

class _TestRunTrackingScreenState extends State<TestRunTrackingScreen> {
  // Run state
  bool _isRunning = false;
  bool _hasCompleted = false;
  
  // Tracking data
  double _totalDistance = 0.0; // in meters
  Duration _elapsedTime = Duration.zero;
  Position? _lastPosition;
  bool _hasReachedTarget = false; // Track if target distance has been reached
  
  // Streams and timers
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;
  Timer? _calibrationTimer;
  DateTime? _startTime;
  
  // Calibration state
  bool _isCalibrating = false;
  int _calibrationCountdown = 5;
  
  // Permission state
  bool _hasPermission = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    // Check permissions but don't auto-start - wait for user to click Start button
    _checkPermissions();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionError = 'Location services are disabled. Please enable GPS.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _permissionError = 'Location permission denied.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionError = 'Location permission permanently denied. Please enable in settings.';
      });
      return;
    }

    setState(() {
      _hasPermission = true;
      _permissionError = null;
    });
  }

  void _startRun() async {
    if (!_hasPermission) {
      await _checkPermissions();
      if (!_hasPermission) return;
    }

    setState(() {
      _isRunning = true;
      _hasCompleted = false;
      _totalDistance = 0.0;
      _elapsedTime = Duration.zero;
      _lastPosition = null;
      _startTime = null; // Don't start timer yet - wait for calibration
      _hasReachedTarget = false;
      _isCalibrating = true; // Start in calibration mode
      _calibrationCountdown = 5; // 5-second calibration period
    });

    // Start GPS position stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Update every 1 meter for more frequent live updates
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // During calibration: just update lastPosition, don't accumulate distance
        if (_isCalibrating) {
          _lastPosition = position;
          debugPrint('📍 Calibration: GPS position updated (not counting distance)');
          return;
        }
        
        // Don't accumulate distance if target has already been reached
        if (_hasReachedTarget) {
          return;
        }
        
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          
          if (mounted) {
            double newDistance = _totalDistance + distance;
            
            // Cap the distance at exactly the target distance
            if (newDistance >= widget.targetDistance) {
              setState(() {
                _totalDistance = widget.targetDistance; // Cap at exactly 30m
                _hasReachedTarget = true;
              });
              
              debugPrint('🎯 Target distance reached! Distance capped at ${widget.targetDistance}m');
              
              // Trigger vibration immediately when distance is reached
              // Ensure vibration happens on main thread
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Use multiple vibrations for better feedback
                HapticFeedback.heavyImpact();
                Future.delayed(const Duration(milliseconds: 150), () {
                  if (mounted) {
                    HapticFeedback.heavyImpact();
                  }
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    HapticFeedback.heavyImpact();
                  }
                });
                debugPrint('📳 Vibration triggered at ${widget.targetDistance}m');
              });
              
              // Stop the run after a brief delay to show the final time
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _hasReachedTarget) {
                  _stopRun();
                }
              });
            } else {
              // Normal distance accumulation (before reaching target)
              setState(() {
                _totalDistance = newDistance;
              });
              
              debugPrint('📍 Distance update: ${_totalDistance.toStringAsFixed(2)}m / ${widget.targetDistance}m');
            }
          }
        }
        _lastPosition = position;
      },
      onError: (error) {
        debugPrint('GPS Error: $error');
      },
    );
    
    // Start calibration countdown timer
    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_calibrationCountdown > 1) {
        setState(() {
          _calibrationCountdown--;
        });
        debugPrint('⏱️ Calibration countdown: $_calibrationCountdown');
      } else {
        timer.cancel();
        // Calibration complete - start actual run timer
        setState(() {
          _isCalibrating = false;
          _startTime = DateTime.now(); // Start timer NOW
        });
        
        // Start timer for elapsed time
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_startTime != null && mounted) {
            setState(() {
              _elapsedTime = DateTime.now().difference(_startTime!);
            });
          }
        });
        
        debugPrint('✅ Calibration complete! Starting run timer and distance tracking.');
      }
    });
  }

  void _stopRun() {
    _stopTracking(); // This stops the timer immediately
    setState(() {
      _isRunning = false;
      _hasCompleted = true;
      _isCalibrating = false; // Reset calibration state
      _calibrationCountdown = 5; // Reset countdown
      // Timer is already stopped by _stopTracking(), elapsedTime won't update anymore
    });
    
    // Trigger vibration on completion (backup - in case it wasn't triggered in GPS listener)
    // Ensure vibration happens on main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use multiple vibrations for better feedback
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          HapticFeedback.heavyImpact();
        }
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          HapticFeedback.heavyImpact();
        }
      });
      debugPrint('📳 Vibration triggered in _stopRun()');
    });
    
    // Navigate to results screen after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _navigateToResults();
      }
    });
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _navigateToResults() {
    final timeTaken = _elapsedTime.inSeconds.toDouble();
    final speed = timeTaken > 0 ? _totalDistance / timeTaken : 0.0;
    
    final testResult = TestResultModel(
      testName: widget.test.name,
      testType: 'running',
      distance: _totalDistance,
      timeTaken: timeTaken,
      speed: speed,
      date: DateTime.now(),
    );
    
    Navigator.pushReplacementNamed(
      context,
      '/test-results',
      arguments: testResult,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  double get _progress {
    if (widget.targetDistance <= 0) return 0.0;
    return (_totalDistance / widget.targetDistance).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.test.name),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isRunning ? null : IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Permission error
            if (_permissionError != null) ...[
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _permissionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Retry'),
              ),
            ] else ...[
              // Progress indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasCompleted ? Colors.green : const Color(0xFFF28D25),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _isCalibrating ? 'Calibrating...' : _formatDistance(_totalDistance),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF322259),
                        ),
                      ),
                      Text(
                        _isCalibrating ? 'GPS stabilizing' : 'of ${_formatDistance(widget.targetDistance)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
              
              const SizedBox(height: 40),
              
              // Time display - make it more prominent when target is reached
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: _hasReachedTarget ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: _hasReachedTarget 
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _isCalibrating 
                        ? '$_calibrationCountdown' 
                        : _formatDuration(_elapsedTime),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _isCalibrating 
                          ? Colors.orange.shade700
                          : (_hasReachedTarget ? Colors.green.shade700 : const Color(0xFF322259)),
                      ),
                    ),
                    Text(
                      _isCalibrating 
                        ? 'Calibrating GPS...' 
                        : (_hasReachedTarget ? 'Final Time' : 'Time'),
                      style: TextStyle(
                        fontSize: 16,
                        color: _isCalibrating 
                          ? Colors.orange.shade700
                          : (_hasReachedTarget ? Colors.green.shade700 : const Color(0xFF888888)),
                        fontWeight: (_isCalibrating || _hasReachedTarget) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Buttons
              if (!_isRunning && !_hasCompleted) ...[
                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startRun,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start Run',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Test vibration button (for debugging)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        HapticFeedback.heavyImpact();
                      });
                      Future.delayed(const Duration(milliseconds: 300), () {
                        HapticFeedback.heavyImpact();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vibration test triggered'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Test Vibration',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ] else if (_isRunning) ...[
                // Stop button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _stopRun,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Stop Run',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isCalibrating ? Colors.orange : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
                    const SizedBox(width: 8),
                    Text(
                      _isCalibrating ? 'Calibrating GPS...' : 'GPS tracking active...',
                      style: TextStyle(
                        color: _isCalibrating ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else if (_hasCompleted) ...[
                // Completed message
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Run Completed!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}



