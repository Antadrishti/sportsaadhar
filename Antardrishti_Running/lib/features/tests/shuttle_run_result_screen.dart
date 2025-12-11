import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/physical_test.dart';
import '../../core/models/test_result_model.dart';
import '../../core/services/shuttle_run_service.dart';
import '../../core/services/test_results_service.dart';
import '../../main.dart';

/// Result screen for shuttle run test
class ShuttleRunResultScreen extends StatefulWidget {
  final PhysicalTest test;
  final ShuttleRunResult result;

  const ShuttleRunResultScreen({
    super.key,
    required this.test,
    required this.result,
  });

  @override
  State<ShuttleRunResultScreen> createState() => _ShuttleRunResultScreenState();
}

class _ShuttleRunResultScreenState extends State<ShuttleRunResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  String? _errorMessage;
  final TestResultsService _testResultsService = TestResultsService();

  Future<void> _saveAndContinue() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppState>();
      final user = appState.user;

      if (user == null) {
        throw Exception('Please login to save test results');
      }

      // Save shuttle run test result (works offline - will save to backend if online)
      final saveResult = await _testResultsService.saveTestResult(
        token: user.token,
        testName: widget.test.name,
        testType: 'agility',
        distance: widget.result.totalDistance,
        timeTaken: widget.result.totalTime.inSeconds.toDouble() +
            (widget.result.totalTime.inMilliseconds % 1000) / 1000.0,
        speed: widget.result.averageSpeed,
        shuttleRunLaps: widget.result.lapsCompleted,
        directionChanges: widget.result.directionChanges,
        averageGpsAccuracy: widget.result.averageGpsAccuracy,
      );

      final isOffline = saveResult['gamification']?['isOffline'] == true;

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });

        // Show appropriate message based on online/offline status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOffline 
              ? '📴 Test result displayed (offline mode - not saved to server)'
              : '✅ Shuttle run result saved successfully!'),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
            duration: Duration(seconds: isOffline ? 3 : 2),
          ),
        );

        // Navigate back to physical assessment after a short delay
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/physical-assessment',
            (route) => route.settings.name == '/home',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $_errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _retryTest() {
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  Color _getResultColor() {
    // Color based on average speed (m/s)
    if (widget.result.averageSpeed >= 3.5) return Colors.green;
    if (widget.result.averageSpeed >= 2.5) return Colors.blue;
    if (widget.result.averageSpeed >= 1.5) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceRating() {
    if (widget.result.averageSpeed >= 3.5) return 'Excellent';
    if (widget.result.averageSpeed >= 2.5) return 'Good';
    if (widget.result.averageSpeed >= 1.5) return 'Average';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = _getResultColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Shuttle Run Result'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_run,
                  color: resultColor,
                  size: 60,
                ),
              ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 24),

              // Test name
              Text(
                widget.test.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF322259),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 8),

              Text(
                'Test Completed Successfully!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Time display - Large
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      resultColor,
                      resultColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: resultColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Total Time',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.result.formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPerformanceRating(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Stats grid
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildStatRow(
                      'Distance Covered',
                      '${widget.result.totalDistance.toStringAsFixed(1)} m',
                      Icons.straighten,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Laps Completed',
                      '${widget.result.lapsCompleted} / 4',
                      Icons.repeat,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Direction Changes',
                      '${widget.result.directionChanges} / 3',
                      Icons.sync,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'Average Speed',
                      '${widget.result.averageSpeed.toStringAsFixed(2)} m/s',
                      Icons.speed,
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      'GPS Accuracy',
                      widget.result.gpsAccuracyRating,
                      Icons.gps_fixed,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Validation warnings
              if (widget.result.lapsCompleted < 4 ||
                  widget.result.directionChanges < 3)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Incomplete',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (widget.result.lapsCompleted < 4)
                              Text(
                                'Only ${widget.result.lapsCompleted} laps completed. Target: 4 laps.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (widget.result.directionChanges < 3)
                              Text(
                                'Only ${widget.result.directionChanges} direction changes detected. Target: 3 changes.',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving || _isSaved ? null : _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF28D25),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _retryTest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF322259),
                    side: const BorderSide(color: Color(0xFF322259), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Retry Test',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF322259), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF322259),
          ),
        ),
      ],
    );
  }
}



