import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../core/models/physical_test.dart';
import '../../core/services/shuttle_run_service.dart';

/// Tracking screen for shuttle run - real-time GPS tracking
class ShuttleRunTrackingScreen extends StatefulWidget {
  final PhysicalTest test;
  final Position startPosition;

  const ShuttleRunTrackingScreen({
    super.key,
    required this.test,
    required this.startPosition,
  });

  @override
  State<ShuttleRunTrackingScreen> createState() =>
      _ShuttleRunTrackingScreenState();
}

class _ShuttleRunTrackingScreenState extends State<ShuttleRunTrackingScreen> {
  final ShuttleRunService _shuttleRunService = ShuttleRunService();
  
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _uiUpdateTimer;
  
  ShuttleRunUpdate? _currentUpdate;
  Duration _elapsedTime = Duration.zero;
  bool _isRunning = false;
  bool _hasStarted = false; // Track if user has clicked Start
  bool _isPaused = false;
  bool _testCompleted = false;
  
  bool _previousLapComplete = false;
  bool _previousWaitingForDirectionChange = false;
  
  // Track milestones to prevent duplicate vibrations
  Set<int> _vibratedMilestones = {}; // Track which milestones (10, 20, 30, 40) have vibrated

  @override
  void initState() {
    super.initState();
    // Don't auto-start - wait for user to click Start button
    _initializeShuttleRun();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeShuttleRun() {
    // Initialize shuttle run service but don't start tracking yet
    // Don't call startShuttleRun() here - wait for user to click Start button
    
    setState(() {
      _isRunning = false;
      _hasStarted = false;
      _isPaused = false;
    });
  }
  
  void _startShuttleRun() {
    // User clicked Start button - begin tracking
    // Now start the shuttle run service (this sets startTime)
    _shuttleRunService.startShuttleRun(widget.startPosition);
    
    setState(() {
      _isRunning = true;
      _hasStarted = true;
      _isPaused = false;
      _vibratedMilestones.clear(); // Reset milestones
    });
    
    // Start listening to position updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 1, // Update every 1 meter for live updates
    );
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!_isPaused && _isRunning && !_testCompleted) {
          _handlePositionUpdate(position);
        }
      },
      onError: (error) {
        debugPrint('Position stream error: $error');
        _showError('GPS tracking error: $error');
      },
    );
    
    // Start UI update timer for elapsed time
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRunning && !_isPaused && !_testCompleted) {
        setState(() {
          _elapsedTime = _shuttleRunService.getElapsedTime();
        });
      }
    });
  }

  void _handlePositionUpdate(Position position) {
    ShuttleRunUpdate update = _shuttleRunService.updatePosition(position);
    
    setState(() {
      _currentUpdate = update;
    });
    
    // Check for total distance milestones (10m, 20m, 30m, 40m)
    double totalDistance = update.totalDistance;
    int currentMilestone = (totalDistance ~/ 10) * 10; // Round down to nearest 10
    
    // Detect when we JUST started waiting for direction change (milestone reached)
    bool justStartedWaiting = update.waitingForDirectionChange && !_previousWaitingForDirectionChange;
    
    // Check if we're waiting for direction change at a milestone
    if (update.waitingForDirectionChange) {
      // Trigger vibration immediately when milestone is reached (just started waiting)
      if (justStartedWaiting) {
        if (totalDistance >= 10.0 && totalDistance <= 10.5 && !_vibratedMilestones.contains(10)) {
          _vibratedMilestones.add(10);
          HapticFeedback.heavyImpact();
          _showDirectionChange(10);
          debugPrint('📳 Vibration triggered at 10m milestone! Distance calculation paused.');
        } else if (totalDistance >= 20.0 && totalDistance <= 20.5 && !_vibratedMilestones.contains(20)) {
          _vibratedMilestones.add(20);
          HapticFeedback.heavyImpact();
          _showDirectionChange(20);
          debugPrint('📳 Vibration triggered at 20m milestone! Distance calculation paused.');
        } else if (totalDistance >= 30.0 && totalDistance <= 30.5 && !_vibratedMilestones.contains(30)) {
          _vibratedMilestones.add(30);
          HapticFeedback.heavyImpact();
          _showDirectionChange(30);
          debugPrint('📳 Vibration triggered at 30m milestone! Distance calculation paused.');
        }
      }
    } else {
      // Not waiting - check if we just passed a milestone (shouldn't happen with proper logic, but backup)
      if (currentMilestone >= 10 && currentMilestone <= 40) {
        if (!_vibratedMilestones.contains(currentMilestone)) {
          _vibratedMilestones.add(currentMilestone);
          
          if (currentMilestone == 40) {
            // Test complete at 40m
            HapticFeedback.heavyImpact();
            _handleTestComplete();
          }
        }
      }
    }
    
    // Update previous waiting state
    _previousWaitingForDirectionChange = update.waitingForDirectionChange;
    
    // Check if lap just completed (for direction change detection)
    if (!_previousLapComplete && update.isLapComplete) {
      // Show lap completion message
      _showLapComplete(update.currentLap);
    }
    
    _previousLapComplete = update.isLapComplete;
    
    // Check if test is complete (backup check)
    if (update.isTestComplete && !_testCompleted) {
      _handleTestComplete();
    }
  }
  
  void _showDirectionChange(int milestone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 ${milestone}m reached! Change direction now!\nDistance calculation paused until direction change.'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLapComplete(int lap) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔄 Lap ${lap + 1} complete! Turn around!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleTestComplete() {
    setState(() {
      _testCompleted = true;
      _isRunning = false;
    });
    
    // Trigger completion haptic (if not already triggered at 40m)
    if (!_vibratedMilestones.contains(40)) {
      HapticFeedback.heavyImpact();
      _vibratedMilestones.add(40);
    }
    
    // Stop streams and timer
    _positionStreamSubscription?.cancel();
    _uiUpdateTimer?.cancel();
    
    // Get result
    ShuttleRunResult result = _shuttleRunService.getResult();
    
    // Navigate to result screen after a short delay to show completion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/shuttle-run-result',
          arguments: {
            'test': widget.test,
            'result': result,
          },
        );
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopTest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Test?'),
        content: const Text('Are you sure you want to stop the test? Progress will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _positionStreamSubscription?.cancel();
              _uiUpdateTimer?.cancel();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    int milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}';
  }

  String _getDirectionLabel(double heading) {
    // Convert heading (0-360 degrees) to cardinal direction label
    // 0° = North, 90° = East, 180° = South, 270° = West
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return 'N';
  }

  Widget _buildMilestoneIndicator(int milestone, double totalDistance) {
    bool reached = totalDistance >= milestone;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: reached ? const Color(0xFFF28D25) : Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: reached ? Colors.white : Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: reached
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(
                '${milestone}m',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalDistance = _currentUpdate?.totalDistance ?? 0.0;
    double progress = (totalDistance / 40.0).clamp(0.0, 1.0); // Progress to 40m total
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with direction arrow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.test.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Direction arrow indicator
                          if (_currentUpdate?.currentHeading != null && _isRunning && !_isPaused)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.rotate(
                                    angle: (_currentUpdate!.currentHeading! * 3.14159 / 180) - (3.14159 / 2),
                                    child: const Icon(
                                      Icons.arrow_upward,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getDirectionLabel(_currentUpdate!.currentHeading!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_testCompleted)
                        const Text(
                          'Test Complete! 🎉',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Total distance indicator
                        Text(
                          'TOTAL DISTANCE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 16),

                        // Distance display - show total distance (0-40m)
                        Text(
                          '${totalDistance.toStringAsFixed(1)}m',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ).animate().fadeIn(duration: 400.ms),

                        const SizedBox(height: 8),

                        Text(
                          '/ 40.0m',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 24,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Milestone indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMilestoneIndicator(10, totalDistance),
                            const SizedBox(width: 8),
                            _buildMilestoneIndicator(20, totalDistance),
                            const SizedBox(width: 8),
                            _buildMilestoneIndicator(30, totalDistance),
                            const SizedBox(width: 8),
                            _buildMilestoneIndicator(40, totalDistance),
                          ],
                        ),
                        
                        // Waiting for direction change message
                        if (_currentUpdate?.waitingForDirectionChange == true && totalDistance < 40.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange, width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pause_circle, color: Colors.orange, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Waiting for direction change...',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Progress bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 20,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF28D25),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}% Complete',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Time display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'TIME',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(_elapsedTime),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),

                // Control buttons
                if (!_testCompleted)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: _hasStarted
                        ? Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _togglePause,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      _isPaused ? 'RESUME' : 'PAUSE',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _stopTest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'STOP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _startShuttleRun,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF28D25),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'START',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),

            // Paused overlay
            if (_isPaused)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pause_circle_outline,
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

