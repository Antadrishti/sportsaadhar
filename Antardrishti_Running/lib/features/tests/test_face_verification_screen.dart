import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/video_recorder_widget.dart';
import '../../core/services/face_verification_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/models/face_verification_result.dart';
import '../../core/models/physical_test.dart';
import '../../main.dart';

class TestFaceVerificationScreen extends StatefulWidget {
  final PhysicalTest test;
  final double targetDistance; // in meters

  const TestFaceVerificationScreen({
    super.key,
    required this.test,
    required this.targetDistance,
  });

  @override
  State<TestFaceVerificationScreen> createState() => _TestFaceVerificationScreenState();
}

class _TestFaceVerificationScreenState extends State<TestFaceVerificationScreen> {
  bool _isProcessing = false;
  FaceVerificationResult? _verificationResult;
  final FaceVerificationService _faceVerificationService = FaceVerificationService();
  final ImageStorageService _imageStorageService = ImageStorageService();
  
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
    });
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
      
      final imagePath = await _imageStorageService.getProfileImagePath(user.aadhaarNumber);
      
      if (imagePath != null) {
        setState(() {
          _profileImagePath = imagePath;
          _isProfileImageLoaded = true;
          _profileImageError = null;
        });
      } else {
        setState(() {
          _profileImageError = 'Profile image not found. Please update your profile.';
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

  Future<void> _handleVideoSaved(String videoPath) async {
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
        throw Exception('Profile image not found. Please update your profile with a photo.');
      }

      await _faceVerificationService.initialize();

      final result = await _faceVerificationService.verifyFace(
        referenceImagePath: _profileImagePath!,
        videoPath: videoPath,
        threshold: 0.70,
        sampleFrames: 5,
      );

      if (mounted) {
        setState(() {
          _verificationResult = result;
          _isProcessing = false;
        });

        if (result.isMatch) {
          // Success! Navigate to test run tracking screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Face Verified! Starting test...'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to test run tracking screen after a short delay
          await Future.delayed(const Duration(seconds: 2));
          
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/test-run-tracking',
              arguments: {
                'test': widget.test,
                'targetDistance': widget.targetDistance,
              },
            );
          }
        } else {
          // Verification failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Face Verification Failed\nConfidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%'),
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
                  onPressed: () => Navigator.pushReplacementNamed(context, '/welcome'),
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
                Column(
                  children: [
                    // Instructions
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        border: Border(
                          bottom: BorderSide(color: Colors.orange.shade200, width: 1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade800),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Face Verification Required',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Record a short video of your face to verify your identity before starting the test.',
                            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                    // Video recorder
                    Expanded(
                      child: VideoRecorderWidget(
                        onVideoSaved: _handleVideoSaved,
                        maxDuration: const Duration(seconds: 5),
                      ),
                    ),
                  ],
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
                          const Text(
                            'Verifying your face...',
                            style: TextStyle(
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



