import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/jump_analyzer.dart';
import '../utils/constants.dart';
import 'results_screen.dart';

/// Camera screen for recording the vertical jump
class CameraScreen extends StatefulWidget {
  final double heightCm;

  const CameraScreen({super.key, required this.heightCm});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  int _countdown = 0;
  int _recordingSeconds = 0;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  String _statusMessage = 'Initializing camera...';
  double _processingProgress = 0;
  String _processingStatus = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    // Request permissions
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    
    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      setState(() {
        _statusMessage = 'Camera and microphone permissions required';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
        });
        return;
      }

      // Use back camera
      final backCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Ready! Tap record to start';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = AppConstants.countdownSeconds;
      _statusMessage = 'Get ready...';
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _startRecording();
      }
    });
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _countdown = 0;
        _recordingSeconds = 0;
        _statusMessage = 'Recording... Jump now!';
      });

      // Recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingSeconds++);
        
        if (_recordingSeconds >= AppConstants.maxRecordingDurationSeconds) {
          timer.cancel();
          _stopRecording();
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    _recordingTimer?.cancel();

    try {
      final videoFile = await _controller!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _statusMessage = 'Processing video...';
      });

      await _processVideo(videoFile.path);
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _statusMessage = 'Failed to stop recording: $e';
      });
    }
  }

  Future<void> _processVideo(String videoPath) async {
    final analyzer = JumpAnalyzer();
    
    try {
      // Extract frames from video
      setState(() {
        _processingProgress = 0.05;
        _processingStatus = 'Extracting video frames...';
      });

      // Get video info and frames
      final frames = await _extractFramesFromVideo(videoPath);
      
      if (frames.$1.isEmpty) {
        throw Exception('Could not extract frames from video');
      }

      setState(() {
        _processingProgress = 0.1;
        _processingStatus = 'Analyzing poses...';
      });

      // Analyze the video
      final result = await analyzer.analyzeVideo(
        videoPath: videoPath,
        knownHeightCm: widget.heightCm,
        fps: 30.0, // Assuming 30 fps
        frames: frames.$1,
        imageHeight: frames.$2,
        imageWidth: frames.$3,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _processingProgress = progress;
              _processingStatus = status;
            });
          }
        },
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              result: result,
              videoPath: videoPath,
              heightCm: widget.heightCm,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Analysis failed: $e';
        });
      }
    }
  }

  /// Extract frames from video file and convert to InputImage list
  Future<(List<InputImage>, int, int)> _extractFramesFromVideo(String videoPath) async {
    final List<InputImage> frames = [];
    
    // For simplicity, we'll use the ML Kit's InputImage.fromFilePath for each frame
    // In a production app, you'd use a video decoder like ffmpeg or video_player
    
    // For now, we'll process the video by taking snapshots
    // This is a simplified approach - a full implementation would decode the video
    
    final file = File(videoPath);
    if (!await file.exists()) {
      throw Exception('Video file not found');
    }
    
    // Get approximate video dimensions from camera
    final width = _controller?.value.previewSize?.width.toInt() ?? 1080;
    final height = _controller?.value.previewSize?.height.toInt() ?? 1920;
    
    // Create InputImage from the video file
    // Note: This is a simplified version. For frame-by-frame analysis,
    // you would need to decode the video into individual frames
    final inputImage = InputImage.fromFilePath(videoPath);
    
    // For demonstration, we'll process the whole video as one image
    // In production, you'd extract individual frames
    frames.add(inputImage);
    
    return (frames, height, width);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
              ),

            // Guidelines overlay
            if (_isInitialized && !_isProcessing)
              Positioned.fill(
                child: CustomPaint(
                  painter: GuidelinesPainter(),
                ),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _isRecording || _isProcessing ? null : () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Height: ${widget.heightCm.toStringAsFixed(0)} cm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Countdown overlay
            if (_countdown > 0)
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Processing overlay
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF00D9FF),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _processingStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _processingProgress,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_processingProgress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status message
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Recording timer
                    if (_isRecording)
                      Text(
                        '${_recordingSeconds}s / ${AppConstants.maxRecordingDurationSeconds}s',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Record button
                    if (!_isProcessing)
                      GestureDetector(
                        onTap: _isInitialized
                            ? (_isRecording ? _stopRecording : _startCountdown)
                            : null,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: _isRecording ? 32 : 64,
                              height: _isRecording ? 32 : 64,
                              decoration: BoxDecoration(
                                color: _isRecording ? Colors.red : const Color(0xFF00D9FF),
                                borderRadius: BorderRadius.circular(_isRecording ? 8 : 32),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for drawing positioning guidelines
class GuidelinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Center vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Ground line (bottom third)
    final groundY = size.height * 0.85;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      paint,
    );

    // Person outline hint
    final centerX = size.width / 2;
    final personTop = size.height * 0.15;
    final personBottom = groundY;
    final personWidth = size.width * 0.3;

    final personRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - personWidth / 2,
        personTop,
        personWidth,
        personBottom - personTop,
      ),
      const Radius.circular(20),
    );
    
    final dashPaint = Paint()
      ..color = const Color(0xFF00D9FF).withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(personRect, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
