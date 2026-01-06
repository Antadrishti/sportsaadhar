import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'components/pose_painter.dart';

enum JumpPhase { calibrating, ready, measuring, result }

class VerticalJumpScreen extends StatefulWidget {
  const VerticalJumpScreen({super.key});

  @override
  State<VerticalJumpScreen> createState() => _VerticalJumpScreenState();
}

class _VerticalJumpScreenState extends State<VerticalJumpScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  
  // Phase tracking
  JumpPhase _phase = JumpPhase.calibrating;
  String _instruction = "Stand still to calibrate...";
  
  // User height for calibration
  double _userHeightCm = 0.0;
  double _cmPerPixel = 0.0;
  
  // Knee tracking data
  double _baselineKneeY = 0.0;
  double _currentKneeY = 0.0;
  double _minKneeY = double.infinity; // Peak of jump (lowest Y value)
  double _jumpHeightCm = 0.0;
  
  // Calibration data
  double _lastAnkleY = 0.0;
  double _lastNoseY = 0.0;
  int _calibrationFrames = 0;
  double _calibrationKneeSum = 0.0;
  double _calibrationAnkleSum = 0.0;
  double _calibrationNoseSum = 0.0;
  static const int _calibrationFramesNeeded = 30;
  
  // Smoothing buffer
  final List<double> _kneeBuffer = [];
  static const int _bufferSize = 5;
  
  // Debug info
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    _loadUserHeight();
    _initCamera();
    _initPoseDetector();
  }

  Future<void> _loadUserHeight() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userHeightCm = prefs.getDouble('max_height') ?? 170.0; // Default 170cm
    });
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    if (!mounted) return;

    _controller!.startImageStream(_processImage);
    setState(() {});
  }

  void _initPoseDetector() {
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isBusy || _poseDetector == null) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty) {
        final pose = poses.first;
        _processKneeTracking(pose);

        if (mounted) {
          final painter = PosePainter(
            poses, 
            inputImage.metadata!.size, 
            inputImage.metadata!.rotation,
          );
          setState(() {
            _customPaint = CustomPaint(painter: painter);
          });
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _processKneeTracking(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || leftKnee == null || rightKnee == null || 
        leftAnkle == null || rightAnkle == null) return;
    
    // Get average positions
    double rawKneeY = (leftKnee.y + rightKnee.y) / 2;
    double ankleY = (leftAnkle.y + rightAnkle.y) / 2;
    double noseY = nose.y;
    
    // Apply smoothing to knee
    _kneeBuffer.add(rawKneeY);
    if (_kneeBuffer.length > _bufferSize) {
      _kneeBuffer.removeAt(0);
    }
    double smoothedKneeY = _kneeBuffer.reduce((a, b) => a + b) / _kneeBuffer.length;
    _currentKneeY = smoothedKneeY;
    _lastAnkleY = ankleY;
    _lastNoseY = noseY;
    
    // State machine
    switch (_phase) {
      case JumpPhase.calibrating:
        _handleCalibration(smoothedKneeY, ankleY, noseY);
        break;
      case JumpPhase.ready:
        _baselineKneeY = smoothedKneeY;
        _minKneeY = smoothedKneeY;
        break;
      case JumpPhase.measuring:
        // Track peak (minimum Y = highest point)
        if (smoothedKneeY < _minKneeY) {
          _minKneeY = smoothedKneeY;
        }
        break;
      case JumpPhase.result:
        break;
    }
    
    // Update debug info
    _updateDebugInfo();
  }

  void _handleCalibration(double kneeY, double ankleY, double noseY) {
    _calibrationKneeSum += kneeY;
    _calibrationAnkleSum += ankleY;
    _calibrationNoseSum += noseY;
    _calibrationFrames++;
    
    if (_calibrationFrames >= _calibrationFramesNeeded) {
      // Calculate averages
      _baselineKneeY = _calibrationKneeSum / _calibrationFrames;
      double avgAnkleY = _calibrationAnkleSum / _calibrationFrames;
      double avgNoseY = _calibrationNoseSum / _calibrationFrames;
      
      // Calculate scale: pixels from ankle to nose ≈ 90% of height
      double pixelBodyHeight = (avgAnkleY - avgNoseY).abs();
      if (pixelBodyHeight > 50) {
        _cmPerPixel = (_userHeightCm * 0.90) / pixelBodyHeight;
      } else {
        _cmPerPixel = 0.2; // Fallback
      }
      
      setState(() {
        _phase = JumpPhase.ready;
        _instruction = "Calibrated! Tap START to begin.";
      });
    } else {
      setState(() {
        _instruction = "Calibrating... ${_calibrationFrames}/$_calibrationFramesNeeded";
      });
    }
  }

  void _startMeasuring() {
    setState(() {
      _phase = JumpPhase.measuring;
      _instruction = "JUMP NOW!";
      _minKneeY = _baselineKneeY;
    });
    
    // Auto-stop after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _phase == JumpPhase.measuring) {
        _finishJump();
      }
    });
  }

  void _finishJump() {
    // Calculate jump height based on knee displacement
    double pixelJump = (_baselineKneeY - _minKneeY);
    if (pixelJump < 0) pixelJump = 0;
    
    _jumpHeightCm = pixelJump * _cmPerPixel;
    
    // Filter out noise (less than 5cm is likely not a real jump)
    if (_jumpHeightCm < 5.0) {
      _jumpHeightCm = 0.0;
    }
    
    // Submit to API if valid
    if (_jumpHeightCm > 5.0 && _jumpHeightCm < 150.0) {
      ApiService.submitTestResult(
        testName: 'Vertical Jump',
        value: _jumpHeightCm,
        unit: 'cm',
        notes: 'Knee displacement method',
      );
    }
    
    setState(() {
      _phase = JumpPhase.result;
      _instruction = "Jump Complete!";
    });
  }

  void _updateDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln("Phase: ${_phase.name}");
    buffer.writeln("User Height: ${_userHeightCm.toStringAsFixed(0)} cm");
    buffer.writeln("Scale: ${_cmPerPixel.toStringAsFixed(3)} cm/px");
    buffer.writeln("---");
    buffer.writeln("Baseline Knee Y: ${_baselineKneeY.toStringAsFixed(1)} px");
    buffer.writeln("Current Knee Y: ${_currentKneeY.toStringAsFixed(1)} px");
    buffer.writeln("Min Knee Y: ${_minKneeY.toStringAsFixed(1)} px");
    buffer.writeln("---");
    buffer.writeln("Displacement: ${(_baselineKneeY - _minKneeY).toStringAsFixed(1)} px");
    buffer.writeln("Jump Height: ${_jumpHeightCm.toStringAsFixed(1)} cm");
    
    setState(() {
      _debugInfo = buffer.toString();
    });
  }

  void _resetTest() {
    setState(() {
      _phase = JumpPhase.calibrating;
      _instruction = "Stand still to calibrate...";
      _calibrationFrames = 0;
      _calibrationKneeSum = 0.0;
      _calibrationAnkleSum = 0.0;
      _calibrationNoseSum = 0.0;
      _baselineKneeY = 0.0;
      _minKneeY = double.infinity;
      _jumpHeightCm = 0.0;
      _kneeBuffer.clear();
      _debugInfo = "";
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) 
        ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) 
        ?? InputImageFormat.nv21;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: metadata,
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vertical Jump'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTest,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),
          
          // Pose overlay
          if (_customPaint != null) _customPaint!,
          
          // Grid lines for reference
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPainter(
              baselineY: _baselineKneeY,
              currentY: _currentKneeY,
              minY: _minKneeY,
            ),
          ),
          
          // Debug info panel (top-left)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugInfo,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
          
          // Main instruction and result panel (bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getPhaseColor().withOpacity(0.9),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  if (_phase == JumpPhase.ready)
                    ElevatedButton(
                      onPressed: _startMeasuring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      ),
                      child: const Text("START JUMP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  
                  if (_phase == JumpPhase.result) ...[
                    Text(
                      "${_jumpHeightCm.toStringAsFixed(1)} cm",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Displacement: ${(_baselineKneeY - _minKneeY).toStringAsFixed(1)} px × ${_cmPerPixel.toStringAsFixed(3)} cm/px",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetTest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text("Try Again", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor() {
    switch (_phase) {
      case JumpPhase.calibrating:
        return Colors.orange;
      case JumpPhase.ready:
        return Colors.blue;
      case JumpPhase.measuring:
        return Colors.purple;
      case JumpPhase.result:
        return Colors.green;
    }
  }
}

// Custom painter for grid lines
class _GridPainter extends CustomPainter {
  final double baselineY;
  final double currentY;
  final double minY;

  _GridPainter({
    required this.baselineY,
    required this.currentY,
    required this.minY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (baselineY <= 0) return;
    
    final baselinePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2;
    
    final currentPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2;
    
    final peakPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2;
    
    // Draw baseline (green)
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      baselinePaint,
    );
    
    // Draw current knee position (cyan)
    if (currentY > 0) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(size.width, currentY),
        currentPaint,
      );
    }
    
    // Draw peak/min position (yellow) - only if different from baseline
    if (minY < baselineY && minY < double.infinity) {
      canvas.drawLine(
        Offset(0, minY),
        Offset(size.width, minY),
        peakPaint,
      );
    }
    
    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    textPainter.text = const TextSpan(
      text: 'BASELINE',
      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 65, baselineY + 2));
    
    if (minY < baselineY && minY < double.infinity) {
      textPainter.text = const TextSpan(
        text: 'PEAK',
        style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 40, minY - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.baselineY != baselineY ||
           oldDelegate.currentY != currentY ||
           oldDelegate.minY != minY;
  }
}
