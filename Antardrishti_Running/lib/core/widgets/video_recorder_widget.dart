import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/video_service.dart';

/// Reusable video recorder widget that can be used in any test screen.
/// 
/// **IMPORTANT:** After recording is complete, the video path is automatically
/// returned via the [onVideoSaved] callback. Use this path for face matching
/// and further processing.
/// 
/// Usage:
/// ```dart
/// VideoRecorderWidget(
///   onVideoSaved: (videoPath) {
///     // videoPath contains the full path where video is saved
///     // Example: /data/user/0/com.app/files/videos/1234567890.mp4
///     print('Video saved at: $videoPath');
///     
///     // Use this path for:
///     // - Face matching/authentication
///     // - Further processing
///     // - Storing in database
///     await processVideoForFaceMatching(videoPath);
///   },
/// )
/// ```
class VideoRecorderWidget extends StatefulWidget {
  /// Callback function called automatically when video recording is complete.
  /// 
  /// **Returns:** The full file path (String) where the video is saved in local storage.
  /// 
  /// **Path format:** `{ApplicationDocumentsDirectory}/videos/{timestamp}.mp4`
  /// 
  /// Use this path for:
  /// - Face matching/authentication
  /// - Video processing
  /// - Storing reference in database
  /// - Any further operations
  final Function(String videoPath) onVideoSaved;

  /// Callback function called when an error occurs.
  final Function(String error)? onError;

  /// Camera direction (front or back). Defaults to front for face authentication.
  final CameraLensDirection cameraDirection;

  /// Resolution preset for video recording. Defaults to high.
  final ResolutionPreset resolutionPreset;

  /// Whether to enable audio. Defaults to true.
  final bool enableAudio;

  /// Custom instruction text shown below the recording button.
  final String? instructionText;

  /// Maximum duration for video recording. Optional.
  final Duration? maxDuration;

  const VideoRecorderWidget({
    super.key,
    required this.onVideoSaved,
    this.onError,
    this.cameraDirection = CameraLensDirection.front,
    this.resolutionPreset = ResolutionPreset.high,
    this.enableAudio = true,
    this.instructionText,
    this.maxDuration,
  });

  @override
  State<VideoRecorderWidget> createState() => _VideoRecorderWidgetState();
}

class _VideoRecorderWidgetState extends State<VideoRecorderWidget> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _statusMessage;
  bool _isSaving = false;
  bool _hasPermission = false;
  bool _permissionChecked = false;
  Timer? _maxDurationTimer; // Track the auto-stop timer

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndSetup();
  }

  Future<void> _checkPermissionsAndSetup() async {
    // Check camera permission
    var cameraStatus = await Permission.camera.status;
    
    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }

    // Check microphone permission if audio is enabled
    if (widget.enableAudio) {
      var micStatus = await Permission.microphone.status;
      if (micStatus.isDenied) {
        micStatus = await Permission.microphone.request();
      }
      
      if (micStatus.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Microphone permission is permanently denied. Please enable it in settings.';
            _permissionChecked = true;
          });
        }
        widget.onError?.call('Microphone permission denied');
        return;
      }
    }

    if (cameraStatus.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera permission is permanently denied. Please enable it in settings.';
          _permissionChecked = true;
        });
      }
      widget.onError?.call('Camera permission denied');
      return;
    }

    if (cameraStatus.isGranted) {
      setState(() {
        _hasPermission = true;
        _permissionChecked = true;
      });
      await _setupCamera();
    } else {
      if (mounted) {
        setState(() {
          _statusMessage = 'Camera permission denied. Please grant camera access.';
          _permissionChecked = true;
        });
      }
      widget.onError?.call('Camera permission denied');
    }
  }

  Future<void> _setupCamera() async {
    if (!_hasPermission) {
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
        });
        widget.onError?.call('No cameras available');
        return;
      }

      // Find camera with specified direction
      final selectedCamera = cameras.firstWhere(
        (c) => c.lensDirection == widget.cameraDirection,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        selectedCamera,
        widget.resolutionPreset,
        enableAudio: widget.enableAudio,
      );

      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error initializing camera: $e';
        });
        widget.onError?.call('Error initializing camera: $e');
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkPermissionsAndSetup();
      if (!_hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to record video'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera is not ready. Please wait...'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_isRecording) {
      return;
    }

    try {
      await _controller!.startVideoRecording();
      
      if (mounted) {
        setState(() {
          _isRecording = true;
          _statusMessage = null;
        });
      }
      
      // Auto-stop after maxDuration if specified
      // Only set timer if maxDuration is provided
      if (widget.maxDuration != null) {
        _maxDurationTimer?.cancel(); // Cancel any existing timer
        _maxDurationTimer = Timer(widget.maxDuration!, () {
          if (mounted && _isRecording && !_isSaving) {
            debugPrint('⏰ Max duration reached (${widget.maxDuration!.inSeconds}s), auto-stopping recording...');
            _stopRecording();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Error starting recording: $e';
          _isRecording = false;
        });
        widget.onError?.call('Error starting recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    // Cancel the max duration timer if it exists
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    
    if (_controller == null || !_isRecording || _isSaving) {
      debugPrint('⚠️ Stop recording called but conditions not met: controller=${_controller != null}, isRecording=$_isRecording, isSaving=$_isSaving');
      return;
    }

    try {
      debugPrint('🛑 Stopping video recording...');
      final xFile = await _controller!.stopVideoRecording();
      debugPrint('✅ Video recording stopped. File: ${xFile.path}');

      setState(() {
        _isRecording = false;
        _isSaving = true;
        _statusMessage = 'Saving video...';
      });

      // Save video to local storage using VideoService
      final videoService = VideoService();
      final savedPath = await videoService.saveVideo(File(xFile.path));

      // Delete the temporary file created by camera plugin
      try {
        await File(xFile.path).delete();
      } catch (e) {
        debugPrint('Failed to delete temp file: $e');
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Video saved successfully!';
        });

        // ✅ Return the video path via callback
        // This path can now be used for face matching and further processing
        widget.onVideoSaved(savedPath);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video saved to local storage.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Error saving video: $e';
        });
        widget.onError?.call('Error saving video: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ VideoRecorderWidget disposing...');
    // Cancel any pending timers
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    
    // Don't dispose controller if we're still recording or saving
    if (!_isRecording && !_isSaving) {
      _controller?.dispose();
    } else {
      debugPrint('⚠️ Skipping controller dispose - recording=$_isRecording, saving=$_isSaving');
      // Stop recording first if still recording
      if (_isRecording && _controller != null) {
        _controller!.stopVideoRecording().catchError((e) {
          debugPrint('Error stopping recording during dispose: $e');
        });
      }
      // Dispose after a delay to allow saving to complete
      Future.delayed(const Duration(seconds: 2), () {
        _controller?.dispose();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show permission error message
    if (_permissionChecked && !_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _statusMessage ?? 'Camera permission is required',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // Show error message if camera setup failed
    if (_statusMessage != null && !_isInitialized && _controller == null && _permissionChecked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading while checking permissions or initializing
    if (!_permissionChecked || !_isInitialized || _initializeControllerFuture == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    // Show camera preview and controls
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              CameraPreview(_controller!),

              // Recording indicator
              if (_isRecording)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Recording...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Status message overlay
              if (_statusMessage != null && !_isRecording && _isSaving)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Control buttons at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Start/Stop Recording Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving
                              ? null
                              : (_isRecording ? _stopRecording : _startRecording),
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.videocam,
                            size: 24,
                          ),
                          label: Text(
                            _isSaving
                                ? 'Saving...'
                                : (_isRecording
                                    ? 'Stop Recording'
                                    : 'Start Recording'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSaving
                                ? Colors.grey
                                : (_isRecording ? Colors.red : Colors.green),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                        ),
                      ),
                      if (widget.instructionText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.instructionText!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing camera...'),
              ],
            ),
          );
        }
      },
    );
  }
}

