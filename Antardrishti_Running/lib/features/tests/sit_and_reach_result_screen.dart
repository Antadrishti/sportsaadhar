import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/test_result_model.dart';
import '../../core/services/test_results_service.dart';
import '../../core/services/sit_and_reach_service.dart';
import '../../main.dart';

/// Screen to display sit and reach flexibility result
class SitAndReachResultScreen extends StatefulWidget {
  final TestResultModel testResult;

  const SitAndReachResultScreen({
    super.key,
    required this.testResult,
  });

  @override
  State<SitAndReachResultScreen> createState() =>
      _SitAndReachResultScreenState();
}

class _SitAndReachResultScreenState extends State<SitAndReachResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  String? _errorMessage;
  final TestResultsService _testResultsService = TestResultsService();
  final SitAndReachService _flexibilityService = SitAndReachService();

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

      // Save sit and reach test result (works offline - will save to backend if online)
      final result = await _testResultsService.saveTestResult(
        token: user.token,
        testName: widget.testResult.testName,
        testType: widget.testResult.testType,
        distance: widget.testResult.distance,
        timeTaken: widget.testResult.timeTaken,
        speed: widget.testResult.speed,
        pace: widget.testResult.pace,
        flexibilityAngle: widget.testResult.flexibilityAngle,
        flexibilityRating: widget.testResult.flexibilityRating,
      );

      final isOffline = result['gamification']?['isOffline'] == true;

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
              : '✅ Flexibility test result saved successfully!'),
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
  }

  Color _getRatingColor(String? rating) {
    switch (rating) {
      case 'elite':
        return Colors.purple;
      case 'excellent':
        return Colors.green;
      case 'very_good':
        return Colors.blue;
      case 'good':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final angle = widget.testResult.flexibilityAngle ?? 180;
    final rating = widget.testResult.flexibilityRating ?? 'good';
    final ratingText = _flexibilityService.getFlexibilityRatingText(rating);
    final ratingColor = _getRatingColor(rating);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Flexibility Test Result'),
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
                  color: ratingColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.accessibility_new,
                  color: ratingColor,
                  size: 60,
                ),
              ).animate().scale(
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 24),

              // Test name
              Text(
                widget.testResult.testName,
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

              // Angle display - Large number
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ratingColor,
                      ratingColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: ratingColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.accessibility_new,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Best Flexibility Angle',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${angle.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ratingText,
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

              // Info card - Lower is better
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
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Lower angle = Better flexibility',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF322259),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rating scale
                    Column(
                      children: [
                        _buildRatingRow('Elite / World-Class', '≤ 30°', Colors.purple),
                        const SizedBox(height: 8),
                        _buildRatingRow('Excellent', '≤ 50°', Colors.green),
                        const SizedBox(height: 8),
                        _buildRatingRow('Very Good', '≤ 70°', Colors.blue),
                        const SizedBox(height: 8),
                        _buildRatingRow('Good - Keep Stretching', '> 70°', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: 40),

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
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

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
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, String range, Color color) {
    final isCurrentRating = (widget.testResult.flexibilityRating == 'elite' && label.contains('Elite')) ||
        (widget.testResult.flexibilityRating == 'excellent' && label.contains('Excellent')) ||
        (widget.testResult.flexibilityRating == 'very_good' && label.contains('Very Good')) ||
        (widget.testResult.flexibilityRating == 'good' && label.contains('Good'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentRating ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentRating ? color : Colors.transparent,
          width: isCurrentRating ? 2 : 0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrentRating ? FontWeight.w600 : FontWeight.normal,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}



