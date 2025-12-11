import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/video_recorder_widget.dart';
import '../../core/services/face_verification_service.dart';
import '../../core/services/image_storage_service.dart';
import '../../core/models/face_verification_result.dart';
import '../../main.dart';

class DemoTesting extends StatefulWidget {
  const DemoTesting({super.key});

  @override
  State<DemoTesting> createState() => _DemoTestingState();
}

class _DemoTestingState extends State<DemoTesting> {
  String? _savedVideoPath;
  bool _isProcessing = false;
  FaceVerificationResult? _verificationResult;
  final FaceVerificationService _faceVerificationService = FaceVerificationService();
  final ImageStorageService _imageStorageService = ImageStorageService();
  
  // User's profile image path (loaded from local storage)
  String? _profileImagePath;
  bool _isProfileImageLoaded = false;
  String? _profileImageError;
  
  /// Load the user's profile image path from local storage
  Future<void> _loadUserProfileImage() async {
    try {
      final state = context.read<AppState>();
      final user = state.user;
      
      if (user == null) {
        setState(() {
          _profileImageError = 'Please login to use face verification';
          _isProfileImageLoaded = true;
        });
        return;
      }
      
      debugPrint('🔍 Loading profile image for user: ${user.aadhaarNumber}');
      
      final imagePath = await _imageStorageService.getProfileImagePath(user.aadhaarNumber);
      
      if (imagePath != null) {
        debugPrint('✅ Profile image found at: $imagePath');
        setState(() {
          _profileImagePath = imagePath;
          _isProfileImageLoaded = true;
          _profileImageError = null;
        });
      } else {
        debugPrint('❌ Profile image not found locally');
        setState(() {
          _profileImageError = 'Profile image not found. Please update your profile.';
          _isProfileImageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading profile image: $e');
      setState(() {
        _profileImageError = 'Error loading profile image: $e';
        _isProfileImageLoaded = true;
      });
    }
  }

  /// This function is called automatically when video recording is complete
  /// The videoPath parameter contains the full path where video is saved
  Future<void> _handleVideoSaved(String videoPath) async {
    setState(() {
      _savedVideoPath = videoPath;
      _isProcessing = true;
    });

    debugPrint('✅ Video saved successfully at: $videoPath');

    // Process the video for face authentication using user's profile image
    await _processVideoForFaceMatching(videoPath);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Process video for face matching using FaceVerificationService
  /// Uses the logged-in user's profile image as reference
  Future<void> _processVideoForFaceMatching(String videoPath) async {
    try {
      // Check if user is logged in
      final state = context.read<AppState>();
      final user = state.user;
      
      if (user == null) {
        throw Exception('Please login to use face verification');
      }
      
      debugPrint('🔍 Processing video for face matching: $videoPath');
      
      // Load profile image path if not already loaded
      if (_profileImagePath == null) {
        await _loadUserProfileImage();
      }
      
      // Check if profile image exists
      if (_profileImagePath == null || _profileImagePath!.isEmpty) {
        throw Exception('Profile image not found. Please update your profile with a photo.');
      }
      
      debugPrint('📸 Using profile image: $_profileImagePath');

      // Initialize face verification service (if not already initialized)
      await _faceVerificationService.initialize();

      // Verify face using the user's profile image as reference
      final result = await _faceVerificationService.verifyFace(
        referenceImagePath: _profileImagePath!,
        videoPath: videoPath,
        threshold: 0.70, // 70% cosine similarity threshold - any frame passing = match
        sampleFrames: 5, // Extract 5 frames from first 5 seconds
      );

      if (mounted) {
        setState(() {
          _verificationResult = result;
        });

        // Show result message to user
        final message = result.isMatch
            ? '✅ Face Verified!\nConfidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%'
            : '❌ Face Verification Failed\nConfidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.isMatch ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        // Log detailed results
        debugPrint('📊 Face Verification Results:');
        debugPrint('   Match: ${result.isMatch}');
        debugPrint('   Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%');
        debugPrint('   Threshold: ${(result.threshold * 100).toStringAsFixed(1)}%');
        debugPrint('   Faces Detected: ${result.facesDetected}');
        debugPrint('   Frames Processed: ${result.framesProcessed}');
        if (result.errorMessage != null) {
          debugPrint('   Error: ${result.errorMessage}');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing video: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _verificationResult = FaceVerificationResult.error(
            errorMessage: 'Failed to process video: ${e.toString()}',
          );
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
  void initState() {
    super.initState();
    // Initialize face verification service on widget initialization
    _faceVerificationService.initialize().catchError((error) {
      debugPrint('⚠️ Face verification service initialization warning: $error');
    });
    // Load user's profile image path after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfileImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    
    // Show error if user is not logged in
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Face Verification'),
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
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please login to use face verification.\nYour profile image will be used as reference.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Show error if profile image is not available
    if (_isProfileImageLoaded && _profileImagePath == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Face Verification'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Profile Image Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _profileImageError ?? 'Please update your profile with a photo to use face verification.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: const Text('Go to Profile'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isProfileImageLoaded = false;
                    });
                    _loadUserProfileImage();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Verification'),
      ),
      body: Stack(
        children: [
          // Video Recorder Widget
          VideoRecorderWidget(
            // This callback is automatically called when video is saved
            // The videoPath parameter contains the full path to the saved video
            onVideoSaved: _handleVideoSaved,
            onError: (error) {
              debugPrint('❌ Video recording error: $error');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            cameraDirection: CameraLensDirection.front, // Front camera for face authentication
            instructionText: 'Record a video to verify your identity',
          ),

          // Show processing indicator if video is being processed
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing video for face matching...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Show saved video path info and verification results
          if (_savedVideoPath != null && !_isProcessing)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Video saved info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Video Saved Successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Path: $_savedVideoPath',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Face verification results
                  if (_verificationResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_verificationResult!.isMatch ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _verificationResult!.isMatch
                                    ? Icons.verified_user
                                    : Icons.cancel,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _verificationResult!.isMatch
                                    ? 'Face Verified'
                                    : 'Face Verification Failed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Confidence: ${(_verificationResult!.confidenceScore * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Threshold: ${(_verificationResult!.threshold * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          if (_verificationResult!.facesDetected > 0)
                            Text(
                              'Faces Detected: ${_verificationResult!.facesDetected}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          if (_verificationResult!.errorMessage != null)
                            Text(
                              'Error: ${_verificationResult!.errorMessage}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}