import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/test_result_model.dart';
import '../../core/services/test_results_service.dart';
import '../../main.dart';

/// Screen to display height verification result
class HeightResultScreen extends StatefulWidget {
  final TestResultModel testResult;

  const HeightResultScreen({
    super.key,
    required this.testResult,
  });

  @override
  State<HeightResultScreen> createState() => _HeightResultScreenState();
}

class _HeightResultScreenState extends State<HeightResultScreen> {
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

      // Save height test result (works offline - will save to backend if online)
      final result = await _testResultsService.saveTestResult(
        token: user.token,
        testName: widget.testResult.testName,
        testType: widget.testResult.testType,
        distance: widget.testResult.distance,
        timeTaken: widget.testResult.timeTaken,
        speed: widget.testResult.speed,
        pace: widget.testResult.pace,
        measuredHeight: widget.testResult.measuredHeight,
        registeredHeight: widget.testResult.registeredHeight,
        isHeightVerified: widget.testResult.isHeightVerified,
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
              : '✅ Height test result saved successfully!'),
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

  @override
  Widget build(BuildContext context) {
    final isVerified = widget.testResult.isHeightVerified ?? false;
    final registeredHeight = widget.testResult.registeredHeight ?? 0;
    final measuredHeight = widget.testResult.measuredHeight;
    
    debugPrint('📊 HeightResultScreen: isVerified=$isVerified, registeredHeight=$registeredHeight, measuredHeight=$measuredHeight');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Height Test Result'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Result icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: measuredHeight != null ? Colors.green.shade50 : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  measuredHeight != null ? Icons.height : Icons.warning_amber,
                  color: measuredHeight != null ? Colors.green : Colors.orange,
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
                measuredHeight != null ? 'Height Measurement Complete' : 'Measurement Incomplete',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 32),

              // Measured Height Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: measuredHeight != null ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: measuredHeight != null ? Colors.green.shade200 : Colors.orange.shade200,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      measuredHeight != null ? Icons.height : Icons.warning_amber,
                      color: measuredHeight != null ? Colors.green : Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    if (measuredHeight != null) ...[
                      const Text(
                        'Measured Height',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF888888),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${measuredHeight!.toStringAsFixed(1)} cm',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF322259),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isVerified ? Icons.check_circle : Icons.info_outline,
                              color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isVerified
                                  ? 'Matches registered height (±7 cm tolerance)'
                                  : 'Difference from registered: ${((measuredHeight! - registeredHeight).abs()).toStringAsFixed(1)} cm',
                              style: TextStyle(
                                fontSize: 13,
                                color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Measurement Failed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF322259),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Height measurement could not be completed.\n\nPlease ensure:\n• Right hand and right foot are clearly visible\n• Good lighting\n• Full body in frame\n• Hold pose steady',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              // Registered height card
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.height,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registered Height',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${registeredHeight.toStringAsFixed(1)} cm',
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
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              // Info card (only show if measurement succeeded)
              if (measuredHeight != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isVerified
                              ? 'Your measured height matches your registered height within acceptable tolerance.'
                              : 'Your measured height differs from your registered height. Please ensure accurate measurement.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

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
}

