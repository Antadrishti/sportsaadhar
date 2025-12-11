import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RunTrackingScreen extends StatefulWidget {
  const RunTrackingScreen({super.key});

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  // Run state
  bool _isRunning = false;
  bool _hasCompleted = false;
  
  // Tracking data
  double _totalDistance = 0.0; // in meters
  Duration _elapsedTime = Duration.zero;
  Position? _lastPosition;
  
  // Streams and timers
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _timer;
  DateTime? _startTime;
  
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
      _startTime = DateTime.now();
    });

    // Start timer for elapsed time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null && mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });

    // Start GPS position stream
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          
          if (mounted) {
            setState(() {
              _totalDistance += distance;
            });
          }
        }
        _lastPosition = position;
      },
      onError: (error) {
        debugPrint('GPS Error: $error');
      },
    );
  }

  void _stopRun() {
    _stopTracking();
    setState(() {
      _isRunning = false;
      _hasCompleted = true;
    });
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void _resetRun() {
    setState(() {
      _isRunning = false;
      _hasCompleted = false;
      _totalDistance = 0.0;
      _elapsedTime = Duration.zero;
      _lastPosition = null;
      _startTime = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Tracker'),
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
              // Time display
              Text(
                _formatDuration(_elapsedTime),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Time',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              
              const SizedBox(height: 40),
              
              // Distance display
              Text(
                _formatDistance(_totalDistance),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Distance',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    ),
                    child: const Text(
                      'Start Run',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    ),
                    child: const Text(
                      'Stop Run',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'GPS tracking active...',
                  style: TextStyle(color: Colors.green),
                ),
              ] else if (_hasCompleted) ...[
                // Results display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Run Completed!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                _formatDistance(_totalDistance),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Distance'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _formatDuration(_elapsedTime),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Time'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _resetRun,
                    child: const Text(
                      'Run Again',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}



