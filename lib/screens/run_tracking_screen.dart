import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/physical_test.dart';
import '../services/test_results_service.dart';
import '../services/api_service.dart';

class RunTrackingScreen extends StatefulWidget {
  final PhysicalTest test;
  final double targetDistance; // in meters

  const RunTrackingScreen({
    super.key,
    required this.test,
    required this.targetDistance,
  });

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  // Service
  final TestResultsService _testResultsService = TestResultsService();

  // Run state
  bool _isRunning = false;
  bool _hasCompleted = false;
  bool _isSaving = false;
  
  // Tracking data
  double _totalDistance = 0.0; // in meters
  Duration _elapsedTime = Duration.zero;
  Position? _lastPosition;
  bool _hasReachedTarget = false;
  
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
      if (mounted) setState(() => _permissionError = 'Location services are disabled. Please enable GPS.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _permissionError = 'Location permission denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _permissionError = 'Location permission permanently denied. Please enable in settings.');
      return;
    }

    if (mounted) {
      setState(() {
        _hasPermission = true;
        _permissionError = null;
      });
    }
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
      _startTime = null;
      _hasReachedTarget = false;
      _isCalibrating = true;
      _calibrationCountdown = 5;
    });

    // Start GPS position stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1, // Update every 1 meter
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (_isCalibrating) {
          _lastPosition = position;
          debugPrint('📍 Calibration: GPS position updated');
          return;
        }
        
        if (_hasReachedTarget) return;
        
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          
          // Basic noise filter: ignore jumps > 20m in 1s (72km/h) which is unlikely for a runner
          if (distance < 20) { 
             if (mounted) {
              double newDistance = _totalDistance + distance;
              
              if (widget.targetDistance > 0 && newDistance >= widget.targetDistance) {
                setState(() {
                  _totalDistance = widget.targetDistance;
                  _hasReachedTarget = true;
                });
                
                _triggerVibration();
                
                // Stop automatically after reaching target
                 Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _hasReachedTarget) {
                    _stopRun();
                  }
                });
              } else {
                setState(() {
                  _totalDistance = newDistance;
                });
              }
            }
          }
        }
        _lastPosition = position;
      },
      onError: (error) {
        debugPrint('GPS Error: $error');
      },
    );
    
    // Calibration Timer
    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_calibrationCountdown > 1) {
        setState(() => _calibrationCountdown--);
      } else {
        timer.cancel();
        setState(() {
          _isCalibrating = false;
          _startTime = DateTime.now();
        });
        
        // Run Timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_startTime != null && mounted) {
            setState(() {
              _elapsedTime = DateTime.now().difference(_startTime!);
            });
          }
        });
      }
    });
  }

  void _triggerVibration() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
    });
  }

  void _stopRun() {
    _stopTracking();
    setState(() {
      _isRunning = false;
      _hasCompleted = true;
      _isCalibrating = false;
    });
    
    _triggerVibration();
    _showCompletionDialog();
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    _calibrationTimer?.cancel();
    _calibrationTimer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> _showCompletionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Run Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${_formatDistance(_totalDistance)}'),
            const SizedBox(height: 8),
            Text('Time: ${_formatDuration(_elapsedTime)}'),
            const SizedBox(height: 8),
            Text('Speed: ${_calculateSpeed().toStringAsFixed(2)} m/s'),
          ],
        ),
        actions: [
          if (!_isSaving)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _totalDistance = 0;
                  _elapsedTime = Duration.zero;
                  _hasCompleted = false;
                });
              },
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: _isSaving ? null : () async {
              // Note: Don't pop yet, wait for save
              await _saveRun();
              if (mounted) Navigator.pop(context); // Close dialog
              if (mounted) Navigator.pop(context); // Close screen
            },
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Text('Save Result'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRun() async {
    setState(() => _isSaving = true);
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Please login to save results');

      await _testResultsService.saveTestResult(
        token: token,
        testName: widget.test.name,
        testType: 'running', // or endurance/speed depending on test
        distance: double.parse(_totalDistance.toStringAsFixed(2)),
        timeTaken: _elapsedTime.inSeconds.toDouble(),
        speed: _calculateSpeed(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Result Saved!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double _calculateSpeed() {
    if (_elapsedTime.inSeconds == 0) return 0.0;
    return _totalDistance / _elapsedTime.inSeconds;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDistance(double meters) {
    return '${meters.toStringAsFixed(1)} m';
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
        foregroundColor: const Color(0xFF322259),
        leading: _isRunning ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_permissionError != null) ...[
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_permissionError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _checkPermissions, child: const Text('Retry')),
            ] else ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: widget.targetDistance > 0 ? _progress : null,
                      strokeWidth: 15,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasCompleted ? Colors.green : const Color(0xFFF28D25),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _isCalibrating ? 'Wait...' : _formatDistance(_totalDistance),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF322259)),
                      ),
                      Text(
                        _isCalibrating ? 'GPS Calibrating' : (widget.targetDistance > 0 ? '/ ${_formatDistance(widget.targetDistance)}' : 'Distance'),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                 ),
                 child: Column(
                   children: [
                     Text(
                       _isCalibrating ? '$_calibrationCountdown' : _formatDuration(_elapsedTime),
                       style: TextStyle(
                         fontSize: 48, 
                         fontWeight: FontWeight.bold, 
                         fontFamily: 'monospace',
                         color: _isCalibrating ? Colors.orange : (_hasCompleted ? Colors.green : Colors.black87)
                       ),
                     ),
                     Text(
                       _isCalibrating ? 'Starting soon' : 'Time',
                       style: const TextStyle(fontSize: 16, color: Colors.grey),
                     ),
                   ],
                 ),
              ),
              const SizedBox(height: 60),
              if (!_isRunning && !_hasCompleted)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startRun,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('START RUN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              else if (_isRunning)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _stopRun,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('STOP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
