import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import '../../core/models/physical_test.dart';
import '../../core/models/test_result_model.dart';

/// Screen for recording video to measure broad jump distance using live pose detection
class BroadJumpRecordingScreen extends StatefulWidget {
  final PhysicalTest test;
  final double userHeightCm;

  const BroadJumpRecordingScreen({
    super.key,
    required this.test,
    required this.userHeightCm,
  });

  @override
  State<BroadJumpRecordingScreen> createState() =>
      _BroadJumpRecordingScreenState();
}

class _BroadJumpRecordingScreenState extends State<BroadJumpRecordingScreen> {
  late CameraController _controller;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );

  // User config
  late final double userHeightM = widget.userHeightCm / 100.0;

  // State variables
  final List<double> baselineHeelY = [];
  final List<double> baselineToeX = [];
  double? baselineHeelYMean;
  double? baselineToeXMean;
  double? heightPixels;
  String state = 'CALIBRATING'; // CALIBRATING, READY, IN_AIR, DONE
  double? takeoffX;
  int? takeoffFrame;
  double? landingX;
  double? jumpDistanceM;
  final int baselineFrames = 50; // Collect baseline over ~2 seconds at 30fps
  final int minAirtimeFrames = 15;
  final int stabilityWindow = 12;
  final List<double> recentToePositions = [];
  int frameCount = 0;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndSetup();
  }

  Future<void> _checkPermissionsAndSetup() async {
    var cameraStatus = await Permission.camera.status;

    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }

    if (cameraStatus.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Camera permission is permanently denied. Please enable it in settings.';
        });
      }
      return;
    }

    if (cameraStatus.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      await _setupCamera();
    } else {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Camera permission denied. Please grant camera access.';
        });
      }
    }
  }

  Future<void> _setupCamera() async {
    if (!_hasPermission) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
        });
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(backCamera, ResolutionPreset.high);
      await _controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Start processing frames when "Start Recording" is clicked
      // Don't start automatically - wait for user to click start
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error initializing camera: $e';
        });
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_controller.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera is not ready. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Reset state for new recording
    _resetState();

    // Start image stream processing
    _controller.startImageStream(_processFrame);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📹 Live processing started - Stand still for calibration!'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetState() {
    baselineHeelY.clear();
    baselineToeX.clear();
    baselineHeelYMean = null;
    baselineToeXMean = null;
    heightPixels = null;
    state = 'CALIBRATING';
    takeoffX = null;
    takeoffFrame = null;
    landingX = null;
    jumpDistanceM = null;
    recentToePositions.clear();
    frameCount = 0;
    setState(() {});
  }

  Future<void> _stopRecording() async {
    await _controller.stopImageStream();

    // If jump is complete, navigate to result screen
    if (state == 'DONE' && jumpDistanceM != null) {
      _handleResult();
    } else {
      // Show error message
      String errorMsg = 'Jump not detected.';
      if (state == 'CALIBRATING') {
        errorMsg = 'Not enough baseline frames. Stand still for first 2 seconds.';
      } else if (state == 'READY') {
        errorMsg = 'No takeoff detected. Make sure to jump clearly.';
      } else if (state == 'IN_AIR') {
        errorMsg = 'Landing not detected. Stay still after landing for 1 second.';
      }

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
  }

  void _handleResult() {
    if (jumpDistanceM == null) return;

    // Determine performance rating
    String rating = 'average';
    if (jumpDistanceM! >= 2.5) {
      rating = 'excellent';
    } else if (jumpDistanceM! >= 2.0) {
      rating = 'good';
    } else if (jumpDistanceM! >= 1.5) {
      rating = 'average';
    } else {
      rating = 'needs_improvement';
    }

    // Create test result
    final testResult = TestResultModel(
      testName: widget.test.name,
      testType: 'lowerBodyStrength',
      distance: jumpDistanceM!,
      timeTaken: 0,
      speed: 0,
      date: DateTime.now(),
      jumpHeight: jumpDistanceM! * 100, // Store in cm
      jumpType: 'broad',
    );

    // Navigate to result screen
    Navigator.pushReplacementNamed(
      context,
      '/broad-jump-result',
      arguments: {
        'testResult': testResult,
        'userHeightCm': widget.userHeightCm,
        'rating': rating,
      },
    );
  }

  Future<void> _processFrame(CameraImage image) async {
    final inputImage = _cameraImageToInputImage(image);
    if (inputImage == null) return;

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) return;

    final pose = poses.first;
    final landmarks = pose.landmarks;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    // Extract key points (ML Kit uses same landmark indices as MediaPipe)
    final nose = landmarks[PoseLandmarkType.nose];
    final leftHeel = landmarks[PoseLandmarkType.leftHeel];
    final rightHeel = landmarks[PoseLandmarkType.rightHeel];
    final leftToe = landmarks[PoseLandmarkType.leftFootIndex];
    final rightToe = landmarks[PoseLandmarkType.rightFootIndex];

    if (nose == null ||
        leftHeel == null ||
        rightHeel == null ||
        leftToe == null ||
        rightToe == null) {
      return;
    }

    final heelY = (leftHeel.y + rightHeel.y) / 2.0;
    final toeX = math.max(leftToe.x, rightToe.x); // Furthest forward toe

    frameCount++;

    // === 1. Calibration Phase ===
    if (frameCount <= baselineFrames) {
      baselineHeelY.add(heelY);
      baselineToeX.add(toeX);
      if (mounted) {
        setState(() {}); // Update status
      }
      return;
    }

    if (heightPixels == null) {
      baselineHeelYMean =
          baselineHeelY.reduce((a, b) => a + b) / baselineHeelY.length;
      baselineToeXMean =
          baselineToeX.reduce((a, b) => a + b) / baselineToeX.length;
      heightPixels = (nose.y - baselineHeelYMean!).abs() *
          height; // Approximate body height in pixels
      state = 'READY';
      if (mounted) {
        setState(() {});
      }
    }

    // === 2. State Machine ===
    if (state == 'READY') {
      final liftThreshold = 0.12 * (heightPixels ?? 1.0);
      if (baselineHeelYMean! - heelY > liftThreshold / height) {
        state = 'IN_AIR';
        takeoffX = baselineToeXMean;
        takeoffFrame = frameCount;
        if (mounted) {
          setState(() {});
        }
      }
    } else if (state == 'IN_AIR') {
      final framesInAir = frameCount - takeoffFrame!;
      recentToePositions.add(toeX);
      if (recentToePositions.length > stabilityWindow) {
        recentToePositions.removeAt(0);
      }

      final landMargin = framesInAir < 20
          ? 0.03
          : framesInAir < 35
              ? 0.05
              : framesInAir < 50
                  ? 0.08
                  : 0.12;

      final heelDiff = (heelY - baselineHeelYMean!) * height;
      final heelsAtBaseline =
          heelDiff.abs() < landMargin * (heightPixels ?? 1.0);

      final isToeStable = recentToePositions.length == stabilityWindow &&
          (recentToePositions.reduce(math.max) -
                  recentToePositions.reduce(math.min)) <
              20 / width;

      if (framesInAir >= minAirtimeFrames &&
          heelsAtBaseline &&
          isToeStable) {
        state = 'DONE';
        landingX = toeX;
        final pixelJump = (landingX! - takeoffX!) * width;
        jumpDistanceM = (pixelJump * userHeightM) / (heightPixels ?? 1.0);
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  InputImage? _cameraImageToInputImage(CameraImage image) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        return null;
      }

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error converting camera image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show permission error message
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Record Test - ${widget.test.name}'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined,
                    size: 64, color: Colors.orange),
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
        ),
      );
    }

    // Show error message if camera setup failed
    if (_statusMessage != null && !_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Record Test - ${widget.test.name}'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
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
        ),
      );
    }

    // Show loading while initializing
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Record Test - ${widget.test.name}'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = _controller.value.aspectRatio;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Record Test - ${widget.test.name}'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Transform.scale(
            scale: previewRatio / deviceRatio,
            child: Center(child: CameraPreview(_controller)),
          ),
          CustomPaint(
            painter: PoseOverlayPainter(
              state: state,
              baselineHeelYMean: baselineHeelYMean,
              takeoffX: takeoffX,
              landingX: landingX,
              jumpDistanceM: jumpDistanceM,
              frameCount: frameCount,
              baselineFrames: baselineFrames,
              previewSize: Size(
                _controller.value.previewSize!.height,
                _controller.value.previewSize!.width,
              ), // Note: swapped due to rotation
            ),
            child: Container(),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State: $state',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  if (jumpDistanceM != null)
                    Builder(
                      builder: (context) {
                        final distance = jumpDistanceM!;
                        return Text(
                          'Jump: ${distance.toStringAsFixed(2)} m',
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  if (frameCount <= baselineFrames)
                    Text(
                      'Calibrating... $frameCount/$baselineFrames',
                      style: const TextStyle(color: Colors.orange, fontSize: 16),
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
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state == 'DONE'
                          ? null
                          : (_controller.value.isStreamingImages
                              ? _stopRecording
                              : _startRecording),
                      icon: Icon(
                        _controller.value.isStreamingImages
                            ? Icons.stop
                            : Icons.videocam,
                        size: 24,
                      ),
                      label: Text(
                        state == 'DONE'
                            ? 'Jump Complete!'
                            : (_controller.value.isStreamingImages
                                ? 'Stop Recording'
                                : 'Start Recording'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state == 'DONE'
                            ? Colors.grey
                            : (_controller.value.isStreamingImages
                                ? Colors.red
                                : Colors.green),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state == 'DONE'
                        ? 'Jump detected! Tap to view results.'
                        : (_controller.value.isStreamingImages
                            ? 'Stand still, jump forward, then TAP STOP when done!'
                            : 'Tap START to begin recording'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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

class PoseOverlayPainter extends CustomPainter {
  final String state;
  final double? baselineHeelYMean;
  final double? takeoffX;
  final double? landingX;
  final double? jumpDistanceM;
  final int frameCount;
  final int baselineFrames;
  final Size previewSize;

  PoseOverlayPainter({
    required this.state,
    this.baselineHeelYMean,
    this.takeoffX,
    this.landingX,
    this.jumpDistanceM,
    required this.frameCount,
    required this.baselineFrames,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Baseline horizontal line
    if (baselineHeelYMean != null && frameCount > baselineFrames) {
      final y = baselineHeelYMean! * size.height;
      paint.color = Colors.yellow;
      paint.strokeWidth = 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Takeoff vertical line
    if (takeoffX != null) {
      final x = takeoffX! * size.width;
      paint.color = Colors.green;
      paint.strokeWidth = 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = const TextSpan(
        text: 'TAKEOFF',
        style: TextStyle(
            color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 5, 60));
    }

    // Landing vertical line
    if (landingX != null) {
      final x = landingX! * size.width;
      paint.color = Colors.red;
      paint.strokeWidth = 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = const TextSpan(
        text: 'LANDING',
        style: TextStyle(
            color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 5, 100));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
