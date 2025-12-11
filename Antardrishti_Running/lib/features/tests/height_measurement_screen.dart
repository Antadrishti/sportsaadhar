import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:camera/camera.dart';
import '../../core/widgets/video_recorder_widget.dart';
import '../../core/models/physical_test.dart';
import '../../core/services/height_measurement_service.dart';
import '../../core/models/test_result_model.dart';
import '../../main.dart';

/// Screen for recording video to measure height
class HeightMeasurementScreen extends StatefulWidget {
  final PhysicalTest test;

  const HeightMeasurementScreen({
    super.key,
    required this.test,
  });

  @override
  State<HeightMeasurementScreen> createState() => _HeightMeasurementScreenState();
}

class _HeightMeasurementScreenState extends State<HeightMeasurementScreen> {
  final HeightMeasurementService _heightService = HeightMeasurementService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _heightService.dispose();
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
            content: Text('📹 Analyzing video for height measurement...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Measure height from video
      debugPrint('🔍 Starting height measurement from video: $videoPath');
      final result = await _heightService.measureHeightFromVideo(videoPath);
      debugPrint('📊 Height measurement result: success=${result.success}, height=${result.heightInCm}cm, error=${result.errorMessage}');

      if (!mounted) return;

      setState(() => _isProcessing = false);

      // Get user's registered height
      final registeredHeight = user.height; // in cm
      debugPrint('📋 User registered height: ${registeredHeight}cm');

      // Always navigate to result screen, even if measurement failed
      // This ensures the user sees the result
      bool isVerified = false;
      double? measuredHeight = result.heightInCm;

      if (result.success && result.heightInCm != null) {
        // Check if measured height is within ±7 cm tolerance
        final difference = (result.heightInCm! - registeredHeight).abs();
        isVerified = difference <= 7.0;

        debugPrint('📏 Measured: ${result.heightInCm!.toStringAsFixed(1)} cm');
        debugPrint('📋 Registered: ${registeredHeight.toStringAsFixed(1)} cm');
        debugPrint('📊 Difference: ${difference.toStringAsFixed(1)} cm');
        debugPrint('✅ Verified: $isVerified');
      } else {
        // Measurement failed - still show result screen with failure status
        debugPrint('❌ Height measurement failed: ${result.errorMessage}');
        isVerified = false;
        measuredHeight = null;
      }

      // Create test result - always create, even if measurement failed
      final testResult = TestResultModel(
        testName: widget.test.name,
        testType: 'height',
        distance: 0,
        timeTaken: 0,
        speed: 0,
        date: DateTime.now(),
        measuredHeight: measuredHeight,
        registeredHeight: registeredHeight,
        isHeightVerified: isVerified,
      );

      debugPrint('🚀 Navigating to result screen with testResult: verified=$isVerified, measuredHeight=$measuredHeight');

      // Navigate to result screen - ALWAYS show result
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/height-result',
          arguments: testResult,
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _handleVideoSaved: $e');
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
        title: Text('Measure Height - ${widget.test.name}'),
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
                            'Height Measurement Instructions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem('1', 'Stand straight against a plain wall'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('2', 'Place your RIGHT index finger on your RIGHT foot'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('3', 'Keep your entire body visible in the frame'),
                    const SizedBox(height: 8),
                    _buildInstructionItem('4', 'Hold the pose steady for 10-15 seconds'),
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
                          Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Make sure your right hand and right foot are clearly visible!',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              // Video recorder with back camera to record the person - user must manually stop
              Expanded(
                child: VideoRecorderWidget(
                  onVideoSaved: _handleVideoSaved,
                  cameraDirection: CameraLensDirection.back, // Use back camera to record the person
                  // No maxDuration - user must tap stop button to end recording
                  instructionText: 'Hold pose for 10-15 seconds, then TAP STOP when done.',
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
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
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

