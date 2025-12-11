import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum BroadJumpPhase { setup, calibrating, ready, jumping, landed, result }

class BroadJumpScreen extends StatefulWidget {
  const BroadJumpScreen({super.key});

  @override
  State<BroadJumpScreen> createState() => _BroadJumpScreenState();
}

class _BroadJumpScreenState extends State<BroadJumpScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  
  BroadJumpPhase _phase = BroadJumpPhase.setup;
  String _instruction = "Enter your height to begin";
  
  // User height for scale calibration
  double _userHeightCm = 170.0;
  final TextEditingController _heightController = TextEditingController(text: "170");
  
  // Scale calibration
  double _cmPerPixel = 0.0;
  double _calibratedBodyHeight = 0.0;
  
  // CORRECTION FACTOR: Based on testing, reduce by ~22% to match real measurements
  // This accounts for perspective distortion and pose detection inaccuracies
  static const double _correctionFactor = 0.78;
  
  // Position tracking
  double _startAnkleX = 0.0;  // Starting position (ankle X)
  double _currentAnkleX = 0.0;
  double _landedAnkleX = 0.0;  // Final position
  
  // Jump detection
  double _baselineAnkleY = 0.0;  // Ground level
  bool _inAir = false;
  bool _hasJumped = false;
  
  // Landing validation
  bool _isStanding = false;  // Check if person is upright
  double _torsoAngle = 0.0;  // Angle to detect if standing
  
  // Result
  double _jumpDistanceCm = 0.0;
  bool _validLanding = false;
  
  // Calibration frames
  int _calibrationFrames = 0;
  double _calibrationAnkleYSum = 0.0;
  double _calibrationNoseYSum = 0.0;
  double _calibrationAnkleXSum = 0.0;
  static const int _calibrationFramesNeeded = 25;
  
  // Smoothing
  final List<double> _ankleXBuffer = [];
  final List<double> _ankleYBuffer = [];
  static const int _bufferSize = 3;
  
  // Timeout for jump detection
  Timer? _jumpTimer;
  
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
      // Use back camera, positioned to see the full jump
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,  // Higher res for better tracking
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
    if (_isBusy || _poseDetector == null || _phase == BroadJumpPhase.setup) return;
    _isBusy = true;

    try {
      final inputImage = _convertImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isNotEmpty && mounted) {
        _trackJump(poses.first);
        setState(() {
          _customPaint = CustomPaint(
            painter: _JumpPainter(
              poses.first, 
              inputImage.metadata!.size, 
              _phase,
              _startAnkleX,
              _cmPerPixel,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Process error: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _trackJump(Pose pose) {
    // Get key landmarks
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (nose == null || leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null || 
        leftAnkle == null || rightAnkle == null) {
      _debugInfo = "Missing landmarks";
      return;
    }
    
    // Calculate positions
    double ankleX = (leftAnkle.x + rightAnkle.x) / 2;
    double ankleY = (leftAnkle.y + rightAnkle.y) / 2;
    double hipX = (leftHip.x + rightHip.x) / 2;
    double hipY = (leftHip.y + rightHip.y) / 2;
    double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    double noseY = nose.y;
    
    // Smooth values
    _ankleXBuffer.add(ankleX);
    _ankleYBuffer.add(ankleY);
    if (_ankleXBuffer.length > _bufferSize) _ankleXBuffer.removeAt(0);
    if (_ankleYBuffer.length > _bufferSize) _ankleYBuffer.removeAt(0);
    
    _currentAnkleX = _ankleXBuffer.reduce((a, b) => a + b) / _ankleXBuffer.length;
    double currentAnkleY = _ankleYBuffer.reduce((a, b) => a + b) / _ankleYBuffer.length;
    
    // Calculate torso angle (to check if standing upright)
    // Standing = shoulder above hip, relatively vertical
    double shoulderHipDist = (shoulderY - hipY).abs();
    double bodyHeight = (ankleY - noseY).abs();
    _torsoAngle = shoulderHipDist > 10 ? (bodyHeight / shoulderHipDist) : 0;
    _isStanding = _torsoAngle > 2.0; // Body is elongated = standing
    
    // State machine
    switch (_phase) {
      case BroadJumpPhase.setup:
        break;
        
      case BroadJumpPhase.calibrating:
        _calibrate(noseY, ankleY, ankleX);
        break;
        
      case BroadJumpPhase.ready:
        // Update starting position continuously until jump starts
        _startAnkleX = _currentAnkleX;
        _baselineAnkleY = currentAnkleY;
        break;
        
      case BroadJumpPhase.jumping:
        _detectJump(currentAnkleY);
        break;
        
      case BroadJumpPhase.landed:
        _validateLanding(currentAnkleY);
        break;
        
      case BroadJumpPhase.result:
        break;
    }
    
    _updateDebug(currentAnkleY);
  }

  void _calibrate(double noseY, double ankleY, double ankleX) {
    _calibrationNoseYSum += noseY;
    _calibrationAnkleYSum += ankleY;
    _calibrationAnkleXSum += ankleX;
    _calibrationFrames++;
    
    if (_calibrationFrames >= _calibrationFramesNeeded) {
      double avgNoseY = _calibrationNoseYSum / _calibrationFrames;
      double avgAnkleY = _calibrationAnkleYSum / _calibrationFrames;
      double avgAnkleX = _calibrationAnkleXSum / _calibrationFrames;
      
      // Calculate pixels from nose to ankle ≈ ~85% of height (more conservative)
      _calibratedBodyHeight = (avgAnkleY - avgNoseY).abs();
      
      if (_calibratedBodyHeight > 50) {
        // Base scale calculation
        double baseScale = (_userHeightCm * 0.85) / _calibratedBodyHeight;
        // Apply correction factor to fix 20-25% overestimation
        _cmPerPixel = baseScale * _correctionFactor;
      } else {
        _cmPerPixel = 0.15; // Conservative fallback
      }
      
      _startAnkleX = avgAnkleX;
      _baselineAnkleY = avgAnkleY;
      
      setState(() {
        _phase = BroadJumpPhase.ready;
        _instruction = "Stand at starting line. Tap JUMP when ready!";
      });
    } else {
      setState(() {
        _instruction = "Calibrating... Stand still. $_calibrationFrames/$_calibrationFramesNeeded";
      });
    }
  }

  void _detectJump(double currentAnkleY) {
    // Detect if feet left ground (ankle Y decreased significantly)
    double jumpThreshold = 30; // pixels
    
    if (!_inAir && currentAnkleY < _baselineAnkleY - jumpThreshold) {
      _inAir = true;
      _hasJumped = true;
      setState(() {
        _instruction = "IN THE AIR!";
      });
    }
    
    // Detect landing (ankle Y returns near baseline AND has moved horizontally)
    if (_inAir && currentAnkleY > _baselineAnkleY - 15) {
      _inAir = false;
      _landedAnkleX = _currentAnkleX;
      
      setState(() {
        _phase = BroadJumpPhase.landed;
        _instruction = "Landed! Checking...";
      });
      
      // Give time to stabilize and check landing
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _phase == BroadJumpPhase.landed) {
          _finishJump();
        }
      });
    }
  }

  void _validateLanding(double currentAnkleY) {
    // Keep tracking position during landing validation
    _landedAnkleX = _currentAnkleX;
    _validLanding = _isStanding;
  }

  void _finishJump() {
    _jumpTimer?.cancel();
    
    // Calculate horizontal distance
    double pixelDistance = (_landedAnkleX - _startAnkleX).abs();
    _jumpDistanceCm = pixelDistance * _cmPerPixel;
    
    // Validate: must have actually jumped and be standing
    _validLanding = _hasJumped && _isStanding && _jumpDistanceCm > 10;
    
    // Cap reasonable values (10cm to 400cm)
    if (_jumpDistanceCm < 10) _jumpDistanceCm = 0;
    if (_jumpDistanceCm > 400) _jumpDistanceCm = 400;
    
    setState(() {
      _phase = BroadJumpPhase.result;
      if (_validLanding) {
        _instruction = "Great jump!";
      } else if (!_hasJumped) {
        _instruction = "No jump detected";
      } else if (!_isStanding) {
        _instruction = "Invalid: Not standing upright";
      } else {
        _instruction = "Try again";
      }
    });
  }

  void _startCalibration() {
    _userHeightCm = double.tryParse(_heightController.text) ?? 170.0;
    if (_userHeightCm < 100) _userHeightCm = 100;
    if (_userHeightCm > 250) _userHeightCm = 250;
    
    setState(() {
      _phase = BroadJumpPhase.calibrating;
      _instruction = "Stand still for calibration...";
    });
  }

  void _startJump() {
    setState(() {
      _phase = BroadJumpPhase.jumping;
      _instruction = "JUMP NOW!";
      _hasJumped = false;
      _inAir = false;
    });
    
    // Timeout after 5 seconds
    _jumpTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _phase == BroadJumpPhase.jumping) {
        setState(() {
          _phase = BroadJumpPhase.result;
          _instruction = "No jump detected";
          _jumpDistanceCm = 0;
          _validLanding = false;
        });
      }
    });
  }

  void _reset() {
    _jumpTimer?.cancel();
    setState(() {
      _phase = BroadJumpPhase.setup;
      _instruction = "Enter your height to begin";
      _calibrationFrames = 0;
      _calibrationAnkleYSum = 0;
      _calibrationNoseYSum = 0;
      _calibrationAnkleXSum = 0;
      _startAnkleX = 0;
      _landedAnkleX = 0;
      _hasJumped = false;
      _inAir = false;
      _jumpDistanceCm = 0;
      _validLanding = false;
      _ankleXBuffer.clear();
      _ankleYBuffer.clear();
    });
  }

  void _updateDebug(double ankleY) {
    double pixelDist = (_currentAnkleX - _startAnkleX).abs();
    double cmDist = pixelDist * _cmPerPixel;
    _debugInfo = "Scale: ${_cmPerPixel.toStringAsFixed(3)} cm/px\n"
                 "Start X: ${_startAnkleX.toStringAsFixed(0)} | Current X: ${_currentAnkleX.toStringAsFixed(0)}\n"
                 "Dist: ${pixelDist.toStringAsFixed(0)}px = ${cmDist.toStringAsFixed(1)}cm\n"
                 "Standing: $_isStanding | InAir: $_inAir";
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
    _jumpTimer?.cancel();
    _heightController.dispose();
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
        title: const Text('Broad Jump'),
        backgroundColor: Colors.indigo,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _reset)],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          if (_customPaint != null) _customPaint!,
          
          // Setup screen - height input
          if (_phase == BroadJumpPhase.setup)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Enter Your Height", style: TextStyle(color: Colors.white, fontSize: 20)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 32),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text("cm", style: TextStyle(color: Colors.white70, fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startCalibration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text("START", style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Position camera sideways\nto see full jump distance",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Result display
          if (_phase == BroadJumpPhase.result)
            Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _validLanding ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _validLanding ? Icons.check_circle : Icons.warning,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _validLanding ? "${_jumpDistanceCm.toStringAsFixed(1)} cm" : "Invalid",
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    if (_validLanding)
                      Text(
                        "(${(_jumpDistanceCm / 100).toStringAsFixed(2)} m)",
                        style: const TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _instruction,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          
          // Debug info
          if (_phase != BroadJumpPhase.setup && _phase != BroadJumpPhase.result)
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black87,
                child: Text(_debugInfo, style: const TextStyle(color: Colors.lime, fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
          
          // Bottom panel
          if (_phase != BroadJumpPhase.setup)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: _getPhaseColor(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _instruction,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_phase == BroadJumpPhase.ready)
                      ElevatedButton(
                        onPressed: _startJump,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("JUMP!", style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    if (_phase == BroadJumpPhase.result)
                      ElevatedButton(
                        onPressed: _reset,
                        child: const Text("Try Again", style: TextStyle(fontSize: 16)),
                      ),
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
      case BroadJumpPhase.setup:
        return Colors.grey;
      case BroadJumpPhase.calibrating:
        return Colors.orange;
      case BroadJumpPhase.ready:
        return Colors.blue;
      case BroadJumpPhase.jumping:
        return Colors.purple;
      case BroadJumpPhase.landed:
        return Colors.teal;
      case BroadJumpPhase.result:
        return _validLanding ? Colors.green : Colors.orange;
    }
  }
}

// Custom painter for jump visualization
class _JumpPainter extends CustomPainter {
  final Pose pose;
  final Size imgSize;
  final BroadJumpPhase phase;
  final double startX;
  final double cmPerPixel;

  _JumpPainter(this.pose, this.imgSize, this.phase, this.startX, this.cmPerPixel);

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / imgSize.width;
    double scaleY = size.height / imgSize.height;

    final dotPaint = Paint()
      ..color = phase == BroadJumpPhase.jumping ? Colors.yellow : Colors.cyan
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw key landmarks
    for (var type in [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
    ]) {
      final lm = pose.landmarks[type];
      if (lm != null) {
        canvas.drawCircle(Offset(lm.x * scaleX, lm.y * scaleY), 8, dotPaint);
      }
    }

    // Draw body lines
    void drawLine(PoseLandmarkType t1, PoseLandmarkType t2) {
      final a = pose.landmarks[t1];
      final b = pose.landmarks[t2];
      if (a != null && b != null) {
        canvas.drawLine(Offset(a.x * scaleX, a.y * scaleY), Offset(b.x * scaleX, b.y * scaleY), linePaint);
      }
    }
    
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftAnkle);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightAnkle);

    // Draw start line
    if (startX > 0 && phase != BroadJumpPhase.calibrating) {
      final startLinePaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 3;
      canvas.drawLine(
        Offset(startX * scaleX, 0),
        Offset(startX * scaleX, size.height),
        startLinePaint,
      );
      
      // Label
      final textPainter = TextPainter(
        text: const TextSpan(text: 'START', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX * scaleX + 5, 20));
    }
  }

  @override
  bool shouldRepaint(covariant _JumpPainter old) => true;
}
