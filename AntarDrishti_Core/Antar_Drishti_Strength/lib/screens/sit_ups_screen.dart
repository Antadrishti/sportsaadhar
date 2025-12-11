import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum SitUpPhase { calibrating, ready, measuring, result }

class SitUpsScreen extends StatefulWidget {
  const SitUpsScreen({super.key});

  @override
  State<SitUpsScreen> createState() => _SitUpsScreenState();
}

class _SitUpsScreenState extends State<SitUpsScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  
  SitUpPhase _phase = SitUpPhase.calibrating;
  String _instruction = "Lie down to calibrate...";
  
  int _repCount = 0;
  bool _isUp = false;
  
  double _currentAngle = 0.0;
  double _baselineAngle = 0.0;
  
  // Thresholds - sit-up is detected when angle DECREASES (torso comes up)
  static const double _upThreshold = 70.0;   // When sitting up, angle is small
  static const double _downThreshold = 140.0; // When lying down, angle is large
  
  int _calibrationFrames = 0;
  double _calibrationAngleSum = 0.0;
  static const int _calibrationFramesNeeded = 20;
  
  final List<double> _angleBuffer = [];
  static const int _bufferSize = 3;
  
  Timer? _testTimer;
  int _remainingSeconds = 60;
  
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initPoseDetector();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.startImageStream(_processImage);
      setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _initPoseDetector() {
    _poseDetector = PoseDetector(options: PoseDetectorOptions(mode: PoseDetectionMode.stream));
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isBusy || _poseDetector == null) return;
    _isBusy = true;

    try {
      final inputImage = _convertImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty && mounted) {
        _trackSitUp(poses.first);
        setState(() {
          _customPaint = CustomPaint(
            painter: _PosePainter(poses.first, inputImage.metadata!.size, _isUp),
          );
        });
      }
    } catch (e) {
      debugPrint('Process error: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _trackSitUp(Pose pose) {
    // Get landmarks
    final shoulder = _getMidpoint(
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.rightShoulder],
    );
    final hip = _getMidpoint(
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.rightHip],
    );
    final knee = _getMidpoint(
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.rightKnee],
    );
    
    if (shoulder == null || hip == null || knee == null) {
      _debugInfo = "Missing landmarks";
      return;
    }
    
    // Calculate angle at HIP between shoulder-hip-knee
    double angle = _getAngle(shoulder, hip, knee);
    
    // Smooth
    _angleBuffer.add(angle);
    if (_angleBuffer.length > _bufferSize) _angleBuffer.removeAt(0);
    _currentAngle = _angleBuffer.reduce((a, b) => a + b) / _angleBuffer.length;
    
    // State machine
    switch (_phase) {
      case SitUpPhase.calibrating:
        _calibrate(_currentAngle);
        break;
      case SitUpPhase.ready:
        break;
      case SitUpPhase.measuring:
        _countRep(_currentAngle);
        break;
      case SitUpPhase.result:
        break;
    }
    
    _updateDebug();
  }

  Offset? _getMidpoint(PoseLandmark? a, PoseLandmark? b) {
    if (a == null || b == null) return null;
    return Offset((a.x + b.x) / 2, (a.y + b.y) / 2);
  }

  double _getAngle(Offset a, Offset b, Offset c) {
    // Angle at point B (hip) between BA and BC
    double ba_x = a.dx - b.dx;
    double ba_y = a.dy - b.dy;
    double bc_x = c.dx - b.dx;
    double bc_y = c.dy - b.dy;
    
    double dot = ba_x * bc_x + ba_y * bc_y;
    double magBA = math.sqrt(ba_x * ba_x + ba_y * ba_y);
    double magBC = math.sqrt(bc_x * bc_x + bc_y * bc_y);
    
    if (magBA == 0 || magBC == 0) return 180.0;
    
    double cosAngle = dot / (magBA * magBC);
    cosAngle = cosAngle.clamp(-1.0, 1.0);
    
    return math.acos(cosAngle) * 180.0 / math.pi;
  }

  void _calibrate(double angle) {
    _calibrationAngleSum += angle;
    _calibrationFrames++;
    
    if (_calibrationFrames >= _calibrationFramesNeeded) {
      _baselineAngle = _calibrationAngleSum / _calibrationFrames;
      setState(() {
        _phase = SitUpPhase.ready;
        _instruction = "Ready! Tap START";
      });
    } else {
      setState(() {
        _instruction = "Calibrating... $_calibrationFrames/$_calibrationFramesNeeded";
      });
    }
  }

  void _countRep(double angle) {
    // Dynamic thresholds based on baseline
    // UP = angle drops significantly from baseline (sitting up)
    // DOWN = angle returns close to baseline (lying down)
    double upThresh = _baselineAngle - 40;  // 40 degrees less than baseline = UP
    double downThresh = _baselineAngle - 15; // 15 degrees less than baseline = DOWN
    
    if (!_isUp && angle < upThresh) {
      _isUp = true;
    } else if (_isUp && angle > downThresh) {
      _isUp = false;
      _repCount++;
    }
    
    setState(() {
      _instruction = "Reps: $_repCount";
    });
  }

  void _updateDebug() {
    double upThresh = _baselineAngle - 40;
    double downThresh = _baselineAngle - 15;
    _debugInfo = "Angle: ${_currentAngle.toStringAsFixed(0)}° | Up<${upThresh.toStringAsFixed(0)}° Down>${downThresh.toStringAsFixed(0)}° | ${_isUp ? 'UP' : 'DOWN'}";
  }

  void _startTest() {
    setState(() {
      _phase = SitUpPhase.measuring;
      _repCount = 0;
      _isUp = false;
      _remainingSeconds = 60;
      _instruction = "GO!";
    });
    
    _testTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _endTest();
      }
    });
  }

  void _endTest() {
    _testTimer?.cancel();
    setState(() {
      _phase = SitUpPhase.result;
      _instruction = "Done! $_repCount sit-ups";
    });
  }

  void _reset() {
    _testTimer?.cancel();
    setState(() {
      _phase = SitUpPhase.calibrating;
      _calibrationFrames = 0;
      _calibrationAngleSum = 0;
      _repCount = 0;
      _isUp = false;
      _remainingSeconds = 60;
      _angleBuffer.clear();
      _instruction = "Lie down to calibrate...";
    });
  }

  InputImage? _convertImage(CameraImage img) {
    if (_controller == null) return null;
    final rot = InputImageRotationValue.fromRawValue(_controller!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
    final fmt = InputImageFormatValue.fromRawValue(img.format.raw) ?? InputImageFormat.nv21;
    
    final bytes = WriteBuffer();
    for (var p in img.planes) bytes.putUint8List(p.bytes);
    
    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rot,
        format: fmt,
        bytesPerRow: img.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sit-Ups'),
        backgroundColor: Colors.deepOrange,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _reset)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (_customPaint != null) _customPaint!,
          
          // Timer
          if (_phase == SitUpPhase.measuring)
            Positioned(
              top: 10, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 10 ? Colors.red : Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("${_remainingSeconds}s", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          
          // Rep counter
          if (_phase == SitUpPhase.measuring || _phase == SitUpPhase.result)
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.deepOrange.withOpacity(0.85), shape: BoxShape.circle),
                child: Text("$_repCount", style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
              ),
            ),
          
          // Debug
          Positioned(
            top: 60, left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black87,
              child: Text(_debugInfo, style: const TextStyle(color: Colors.lime, fontSize: 14, fontFamily: 'monospace')),
            ),
          ),
          
          // Bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: _phase == SitUpPhase.result ? Colors.green : Colors.deepOrange,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_instruction, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_phase == SitUpPhase.ready)
                    ElevatedButton(onPressed: _startTest, child: const Text("START", style: TextStyle(fontSize: 18))),
                  if (_phase == SitUpPhase.measuring)
                    ElevatedButton(onPressed: _endTest, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("STOP")),
                  if (_phase == SitUpPhase.result)
                    ElevatedButton(onPressed: _reset, child: const Text("Try Again")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosePainter extends CustomPainter {
  final Pose pose;
  final Size imgSize;
  final bool isUp;

  _PosePainter(this.pose, this.imgSize, this.isUp);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isUp ? Colors.green : Colors.cyan
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = isUp ? Colors.greenAccent : Colors.cyanAccent
      ..style = PaintingStyle.fill;

    double scaleX = size.width / imgSize.width;
    double scaleY = size.height / imgSize.height;

    void drawLandmark(PoseLandmarkType type) {
      final lm = pose.landmarks[type];
      if (lm != null) {
        canvas.drawCircle(Offset(lm.x * scaleX, lm.y * scaleY), 10, dotPaint);
      }
    }

    void drawLine(PoseLandmarkType t1, PoseLandmarkType t2) {
      final a = pose.landmarks[t1];
      final b = pose.landmarks[t2];
      if (a != null && b != null) {
        canvas.drawLine(Offset(a.x * scaleX, a.y * scaleY), Offset(b.x * scaleX, b.y * scaleY), paint);
      }
    }

    // Draw key points
    for (var t in [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, 
                   PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
                   PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee]) {
      drawLandmark(t);
    }

    // Draw lines
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
  }

  @override
  bool shouldRepaint(covariant _PosePainter old) => old.isUp != isUp;
}
