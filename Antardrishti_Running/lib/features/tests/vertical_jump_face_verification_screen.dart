import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/face_verification_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/services/vertical_jump_measurement_service.dart';
import '../../core/models/face_verification_result.dart';
import '../../core/models/physical_test.dart';
import '../../core/models/test_result_model.dart';
import '../../main.dart';

/// Face verification screen for vertical jump test
class VerticalJumpFaceVerificationScreen extends StatefulWidget {
  final PhysicalTest test;
  final String? videoPath; // Video path from recording screen

  const VerticalJumpFaceVerificationScreen({
    super.key,
    required this.test,
    this.videoPath,
  });

  @override
  State<VerticalJumpFaceVerificationScreen> createState() =>
      _VerticalJumpFaceVerificationScreenState();
}

class _VerticalJumpFaceVerificationScreenState
    extends State<VerticalJumpFaceVerificationScreen> {
  bool _isProcessing = false;
  FaceVerificationResult? _verificationResult;
  final FaceVerificationService _faceVerificationService =
      FaceVerificationService();
  final ImageStorageService _imageStorageService = ImageStorageService();
  final VerticalJumpMeasurementService _jumpService =
      VerticalJumpMeasurementService();

  String? _profileImagePath;
  bool _isProfileImageLoaded = false;
  String? _profileImageError;

  @override
  void initState() {
    super.initState();
    _faceVerificationService.initialize().catchError((error) {
      debugPrint('⚠️ Face verification service initialization warning: $error');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfileImage();
      // If video path is provided, start verification automatically
      if (widget.videoPath != null && widget.videoPath!.isNotEmpty) {
        _verifyFaceFromVideo();
      }
    });
  }

  @override
  void dispose() {
    _jumpService.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfileImage() async {
    try {
      final state = context.read<AppState>();
      final user = state.user;

      if (user == null) {
        setState(() {
          _profileImageError = 'Please login to take tests';
          _isProfileImageLoaded = true;
        });
        return;
      }

      final imagePath =
          await _imageStorageService.getProfileImagePath(user.aadhaarNumber);

      if (imagePath != null) {
        setState(() {
          _profileImagePath = imagePath;
          _isProfileImageLoaded = true;
          _profileImageError = null;
        });
      } else {
        setState(() {
          _profileImageError =
              'Profile image not found. Please update your profile.';
          _isProfileImageLoaded = true;
        });
      }
    } catch (e) {
      setState(() {
        _profileImageError = 'Error loading profile image: $e';
        _isProfileImageLoaded = true;
      });
    }
  }

  Future<void> _verifyFaceFromVideo() async {
    if (widget.videoPath == null) return;

    setState(() => _isProcessing = true);

    try {
      final state = context.read<AppState>();
      final user = state.user;

      if (user == null) {
        throw Exception('Please login to take tests');
      }

      if (_profileImagePath == null) {
        await _loadUserProfileImage();
      }

      if (_profileImagePath == null || _profileImagePath!.isEmpty) {
        throw Exception(
            'Profile image not found. Please update your profile with a photo.');
      }

      await _faceVerificationService.initialize();

      final result = await _faceVerificationService.verifyFace(
        referenceImagePath: _profileImagePath!,
        videoPath: widget.videoPath!,
        threshold: 0.70,
        sampleFrames: 5,
      );

      if (mounted) {
        setState(() {
          _verificationResult = result;
        });

        if (result.isMatch) {
          // Success! Now analyze the test
          await _analyzeTest();
        } else {
          // Verification failed
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '❌ Face Verification Failed\nConfidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _verificationResult = FaceVerificationResult.error(
            errorMessage: 'Failed to process video: ${e.toString()}',
          );
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _analyzeTest() async {
    try {
      if (widget.videoPath == null) return;

      final state = context.read<AppState>();
      final user = state.user;

      if (user == null) {
        throw Exception('Please login to take tests');
      }

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
        widget.videoPath!,
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
        String errorMsg = result.errorMessage ?? 'Failed to measure jump height';
        
        if (result.calibrated == false) {
          errorMsg += '\n\nTip: Stand still for 2-3 seconds before jumping.';
        } else if (result.calibrated == true && result.jumpHeightCm == null) {
          errorMsg += '\n\nTip: Make sure both feet are visible throughout the jump.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
    final state = context.watch<AppState>();
    final user = state.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Face Verification'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please login to take tests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/welcome'),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Verify Face - ${widget.test.name}'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProfileImageLoaded && _profileImageError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _profileImageError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.videoPath == null)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No video provided. Please record a test first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      else
                        Column(
                          children: [
                            const Icon(
                              Icons.face,
                              size: 80,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Verifying your identity...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Video recorded: ${widget.videoPath!.split('/').last}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Processing overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.videoPath != null
                                ? 'Verifying face and analyzing test...'
                                : 'Verifying your face...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
