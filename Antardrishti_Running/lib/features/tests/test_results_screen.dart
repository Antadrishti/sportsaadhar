import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/test_result_model.dart';
import '../../core/services/test_results_service.dart';
import '../../core/widgets/xp_gain_animation.dart';
import '../../main.dart';

class TestResultsScreen extends StatefulWidget {
  final TestResultModel testResult;

  const TestResultsScreen({
    super.key,
    required this.testResult,
  });

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  String? _errorMessage;
  Map<String, dynamic>? _gamificationData;
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

      final response = await _testResultsService.saveTestResult(
        token: user.token,
        testName: widget.testResult.testName,
        testType: widget.testResult.testType,
        distance: widget.testResult.distance,
        timeTaken: widget.testResult.timeTaken,
        speed: widget.testResult.speed,
        pace: widget.testResult.pace,
      );

      final isOffline = response['gamification']?['isOffline'] == true;

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
          _gamificationData = response['gamification'] as Map<String, dynamic>?;
        });

        // Only refresh progress if online (offline mode won't have updated progress)
        if (!isOffline) {
          await appState.refreshProgress();
        }

        // Show appropriate message based on online/offline status
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOffline 
              ? '📴 Test result displayed (offline mode - not saved to server)'
              : '✅ Test result saved successfully!'),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
            duration: Duration(seconds: isOffline ? 3 : 2),
          ),
        );

        // Wait for XP animation to complete (4 seconds) before navigating
        await Future.delayed(const Duration(seconds: 4));
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Test Results'),
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
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
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

              // Results cards
              _ResultCard(
                icon: Icons.straighten,
                label: 'Distance',
                value: widget.testResult.formattedDistance,
                color: const Color(0xFF2196F3),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              _ResultCard(
                icon: Icons.timer,
                label: 'Time',
                value: widget.testResult.formattedTime,
                color: const Color(0xFF4CAF50),
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              _ResultCard(
                icon: Icons.speed,
                label: 'Average Speed',
                value: widget.testResult.formattedSpeed,
                color: const Color(0xFFF28D25),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              _ResultCard(
                icon: Icons.directions_run,
                label: 'Pace',
                value: widget.testResult.formattedPace,
                color: const Color(0xFF9C27B0),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 40),

              // XP Gain Animation (shown after save)
              if (_isSaved && _gamificationData != null) ...[
                XPGainAnimation(
                  totalXP: _gamificationData!['xpEarned'] ?? 0,
                  baseXP: _gamificationData!['xpBreakdown']?['base'] ?? 30,
                  ratingBonusXP: _gamificationData!['xpBreakdown']?['ratingBonus'] ?? 0,
                  improvementBonusXP: _gamificationData!['xpBreakdown']?['improvementBonus'] ?? 0,
                  rating: _gamificationData!['performanceRating'],
                  isPersonalBest: _gamificationData!['isPersonalBest'] ?? false,
                ).animate().fadeIn(delay: 100.ms, duration: 500.ms).scale(
                      delay: 100.ms,
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 24),
              ],

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
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

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
              ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF322259),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

