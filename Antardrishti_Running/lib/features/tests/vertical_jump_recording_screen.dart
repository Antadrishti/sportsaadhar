import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import '../../core/widgets/video_recorder_widget.dart';
import '../../core/models/physical_test.dart';
import '../../core/services/vertical_jump_measurement_service.dart';
import '../../core/models/test_result_model.dart';
import '../../main.dart';

/// Screen for recording video to measure vertical jump
class VerticalJumpRecordingScreen extends StatefulWidget {
  final PhysicalTest test;

  const VerticalJumpRecordingScreen({
    super.key,
    required this.test,
  });

  @override
  State<VerticalJumpRecordingScreen> createState() =>
      _VerticalJumpRecordingScreenState();
}

class _VerticalJumpRecordingScreenState
    extends State<VerticalJumpRecordingScreen> {
  final VerticalJumpMeasurementService _jumpService = VerticalJumpMeasurementService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _jumpService.dispose();
    super.dispose();
  }

  Future<void> _handleVideoSaved(String videoPath) async {
    final state = context.read<AppState>();
    final user = state.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to take tests'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isProcessing = true);
    }

    try {
      // Show processing message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📹 Analyzing video for vertical jump measurement...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Measure jump height from video using user's profile height
      final result = await _jumpService.measureJumpFromVideo(
        videoPath,
        user.height, // User's height in cm from profile
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (result.success && result.jumpHeightCm != null) {
        debugPrint('🎯 Jump Height: ${result.jumpHeightCm!.toStringAsFixed(1)} cm');

        // Create test result
        final testResult = TestResultModel(
          testName: widget.test.name,
          testType: 'vertical_jump',
          distance: 0,
          timeTaken: 0,
          speed: 0,
          date: DateTime.now(),
          jumpHeight: result.jumpHeightCm,
          jumpType: 'vertical',
        );

        // Navigate to result screen
        Navigator.pushReplacementNamed(
          context,
          '/vertical-jump-result',
          arguments: testResult,
        );
      } else {
        // Measurement failed
        String errorMsg = result.errorMessage ?? 'Failed to measure vertical jump';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing test: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Record Jump - ${widget.test.name}'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade200, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade800),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Vertical Jump Recording Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                        '1', 'Place camera 6-10 feet away (full body visible)'),
                    const SizedBox(height: 8),
                    _buildInstructionItem(
                        '2', 'Stand still for 2-3 seconds (calibration)'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('3', 'Jump as HIGH as you can'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('4', 'Land and stay in frame'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('5', 'TAP STOP button when done'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Keep entire body in frame throughout! Both feet must be visible.',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              // Video recorder with back camera - user must manually stop
              Expanded(
                child: VideoRecorderWidget(
                  onVideoSaved: _handleVideoSaved,
                  cameraDirection: CameraLensDirection.back,
                  // No maxDuration - user must tap stop button to end recording
                  instructionText: 'Stand still 2-3s, jump high, then TAP STOP when done!',
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing video...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF2196F3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ),
      ],
    );
  }
}

