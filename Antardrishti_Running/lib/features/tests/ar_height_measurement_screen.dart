import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../core/services/ar_height_measurement_service.dart';
import '../../core/models/physical_test.dart';

/// AR-based Height Measurement Screen
/// 
/// Provides real-time visual feedback and accurate height measurement
/// using pose detection and depth estimation.
class ARHeightMeasurementScreen extends StatefulWidget {
  final PhysicalTest test;

  const ARHeightMeasurementScreen({
    super.key,
    required this.test,
  });

  @override
  State<ARHeightMeasurementScreen> createState() => _ARHeightMeasurementScreenState();
}

class _ARHeightMeasurementScreenState extends State<ARHeightMeasurementScreen>
    with TickerProviderStateMixin {
  // Services
  late ARHeightMeasurementService _measurementService;
  CameraController? _cameraController;
  
  // State
  bool _isInitializing = true;
  String _statusMessage = 'Initializing camera...';
  ARMeasurementState _measurementState = ARMeasurementState.initializing;
  double? _currentHeight;
  double _confidence = 0.0;
  double? _progress;
  
  // Pose overlay
  Pose? _currentPose;
  Size? _imageSize;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  // Colors based on state
  Color get _stateColor {
    switch (_measurementState) {
      case ARMeasurementState.completed:
        return const Color(0xFF00C853);
      case ARMeasurementState.error:
        return const Color(0xFFFF5252);
      case ARMeasurementState.measuring:
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFFFFAB00);
    }
  }
  
  @override
  void initState() {
    super.initState();
    
    // Lock to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Initialize measurement service
      _measurementService = ARHeightMeasurementService();
      
      // Set callbacks
      _measurementService.onStateChanged = _onMeasurementStateChanged;
      _measurementService.onHeightUpdate = _onHeightUpdate;
      
      await _measurementService.initialize();
      
      // Initialize camera
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      
      await _cameraController!.initialize();
      
      // Set camera controller in service
      _measurementService.setCameraController(_cameraController!);
      
      // Start processing frames
      await _cameraController!.startImageStream(_processFrame);
      
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Point camera at ground, then step back';
      });
      
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _statusMessage = 'Error: ${e.toString()}';
        _measurementState = ARMeasurementState.error;
      });
    }
  }
  
  void _processFrame(CameraImage image) {
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    _measurementService.processFrame(image);
  }
  
  void _onMeasurementStateChanged(
    ARMeasurementState state,
    String message,
    double? progress,
  ) {
    if (!mounted) return;
    
    setState(() {
      _measurementState = state;
      _statusMessage = message;
      _progress = progress;
    });
    
    if (state == ARMeasurementState.completed) {
      _pulseController.stop();
      _cameraController?.stopImageStream();
      
      // Show completion animation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _navigateToResult();
        }
      });
    }
  }
  
  void _onHeightUpdate(double? heightCm, double confidence) {
    if (!mounted) return;
    
    setState(() {
      _currentHeight = heightCm;
      _confidence = confidence;
    });
  }
  
  void _navigateToResult() {
    final result = _measurementService.getResult();
    
    Navigator.pushReplacementNamed(
      context,
      '/height-result',
      arguments: {
        'test': widget.test,
        'heightCm': result.heightCm ?? _currentHeight,
        'confidence': result.confidence ?? _confidence,
        'isARMeasurement': true,
      },
    );
  }
  
  void _resetMeasurement() {
    _measurementService.reset();
    setState(() {
      _currentHeight = null;
      _confidence = 0.0;
      _progress = null;
    });
    
    // Restart camera stream if stopped
    if (_cameraController != null && 
        !_cameraController!.value.isStreamingImages) {
      _cameraController!.startImageStream(_processFrame);
    }
    
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _cameraController?.dispose();
    _measurementService.dispose();
    
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          _buildCameraPreview(),
          
          // Pose overlay
          if (_currentPose != null && _imageSize != null)
            _buildPoseOverlay(),
          
          // AR guide overlay
          _buildARGuideOverlay(),
          
          // Status bar at top
          _buildStatusBar(),
          
          // Height display
          if (_currentHeight != null)
            _buildHeightDisplay(),
          
          // Instructions panel at bottom
          _buildInstructionsPanel(),
          
          // Loading overlay
          if (_isInitializing)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }
  
  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
  
  Widget _buildPoseOverlay() {
    // This would show skeleton overlay - simplified for now
    return const SizedBox.shrink();
  }
  
  Widget _buildARGuideOverlay() {
    return CustomPaint(
      painter: _ARGuidePainter(
        state: _measurementState,
        stateColor: _stateColor,
        pulseAnimation: _pulseController,
      ),
      child: const SizedBox.expand(),
    );
  }
  
  Widget _buildStatusBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black38,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AR Height Measurement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.test.name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // State indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _stateColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _stateColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStateIcon(),
                    const SizedBox(width: 6),
                    Text(
                      _getStateLabel(),
                      style: TextStyle(
                        color: _stateColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2);
  }
  
  Widget _buildStateIcon() {
    switch (_measurementState) {
      case ARMeasurementState.completed:
        return Icon(Icons.check_circle, color: _stateColor, size: 16);
      case ARMeasurementState.error:
        return Icon(Icons.error, color: _stateColor, size: 16);
      case ARMeasurementState.measuring:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
          ),
        );
      default:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Icon(
            Icons.radio_button_checked,
            color: _stateColor.withOpacity(0.5 + 0.5 * _pulseController.value),
            size: 16,
          ),
        );
    }
  }
  
  String _getStateLabel() {
    switch (_measurementState) {
      case ARMeasurementState.initializing:
        return 'Starting';
      case ARMeasurementState.detectingGround:
        return 'Scanning';
      case ARMeasurementState.waitingForPerson:
        return 'Waiting';
      case ARMeasurementState.trackingPerson:
        return 'Tracking';
      case ARMeasurementState.stabilizing:
        return 'Stabilizing';
      case ARMeasurementState.measuring:
        return 'Measuring';
      case ARMeasurementState.completed:
        return 'Done';
      case ARMeasurementState.error:
        return 'Error';
    }
  }
  
  Widget _buildHeightDisplay() {
    final heightStr = _currentHeight!.toStringAsFixed(1);
    final feet = (_currentHeight! / 30.48).floor();
    final inches = ((_currentHeight! / 2.54) % 12).round();
    
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.15,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _stateColor.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _stateColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main height display
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    heightStr,
                    style: TextStyle(
                      color: _stateColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'cm',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Imperial conversion
              Text(
                '$feet\' $inches"',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Confidence bar
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Confidence: ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(_confidence * 100).toInt()}%',
                        style: TextStyle(
                          color: _stateColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      value: _confidence,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
  }
  
  Widget _buildInstructionsPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
          top: 60,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator (if applicable)
            if (_progress != null && _measurementState == ARMeasurementState.stabilizing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(_stateColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress! * 100).toInt()}% stable',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Status message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _stateColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _stateColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildInstructionIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_measurementState == ARMeasurementState.error ||
                    _measurementState == ARMeasurementState.completed)
                  _buildActionButton(
                    onPressed: _resetMeasurement,
                    icon: Icons.refresh,
                    label: 'Try Again',
                    color: Colors.white,
                  ),
                
                if (_measurementState == ARMeasurementState.completed)
                  const SizedBox(width: 16),
                
                if (_measurementState == ARMeasurementState.completed)
                  _buildActionButton(
                    onPressed: _navigateToResult,
                    icon: Icons.check,
                    label: 'Continue',
                    color: _stateColor,
                    filled: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionIcon() {
    IconData icon;
    switch (_measurementState) {
      case ARMeasurementState.detectingGround:
        icon = Icons.explore;
        break;
      case ARMeasurementState.waitingForPerson:
        icon = Icons.person_search;
        break;
      case ARMeasurementState.trackingPerson:
        icon = Icons.person_pin;
        break;
      case ARMeasurementState.stabilizing:
        icon = Icons.accessibility_new;
        break;
      case ARMeasurementState.measuring:
        icon = Icons.straighten;
        break;
      case ARMeasurementState.completed:
        icon = Icons.check_circle;
        break;
      case ARMeasurementState.error:
        icon = Icons.warning_amber;
        break;
      default:
        icon = Icons.hourglass_empty;
    }
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) {
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _stateColor.withOpacity(0.2 + 0.1 * _pulseController.value),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _stateColor,
            size: 24,
          ),
        );
      },
    );
  }
  
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: filled ? Colors.black : color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for AR guide overlay
class _ARGuidePainter extends CustomPainter {
  final ARMeasurementState state;
  final Color stateColor;
  final Animation<double> pulseAnimation;
  
  _ARGuidePainter({
    required this.state,
    required this.stateColor,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = stateColor.withOpacity(0.3 + 0.2 * pulseAnimation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw human silhouette guide
    if (state == ARMeasurementState.waitingForPerson ||
        state == ARMeasurementState.trackingPerson ||
        state == ARMeasurementState.stabilizing) {
      _drawHumanGuide(canvas, size, paint);
    }
    
    // Draw corner guides
    _drawCornerGuides(canvas, size, paint);
    
    // Draw center crosshair for ground detection
    if (state == ARMeasurementState.detectingGround) {
      _drawCrosshair(canvas, size, paint);
    }
  }
  
  void _drawHumanGuide(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final guideHeight = size.height * 0.7;
    final guideWidth = guideHeight * 0.35;
    final topY = size.height * 0.1;
    
    final path = Path();
    
    // Head (circle)
    final headRadius = guideWidth * 0.25;
    final headCenterY = topY + headRadius;
    
    path.addOval(Rect.fromCircle(
      center: Offset(centerX, headCenterY),
      radius: headRadius,
    ));
    
    // Body outline (simplified)
    final shoulderY = headCenterY + headRadius + 10;
    final hipY = topY + guideHeight * 0.5;
    final footY = topY + guideHeight;
    
    // Shoulders
    path.moveTo(centerX - guideWidth / 2, shoulderY);
    path.lineTo(centerX + guideWidth / 2, shoulderY);
    
    // Body sides
    path.moveTo(centerX - guideWidth / 2, shoulderY);
    path.lineTo(centerX - guideWidth / 3, hipY);
    path.lineTo(centerX - guideWidth / 3, footY);
    
    path.moveTo(centerX + guideWidth / 2, shoulderY);
    path.lineTo(centerX + guideWidth / 3, hipY);
    path.lineTo(centerX + guideWidth / 3, footY);
    
    // Feet line
    path.moveTo(centerX - guideWidth / 2, footY);
    path.lineTo(centerX + guideWidth / 2, footY);
    
    canvas.drawPath(path, paint);
  }
  
  void _drawCornerGuides(Canvas canvas, Size size, Paint paint) {
    const cornerSize = 40.0;
    const margin = 20.0;
    
    final corners = [
      // Top left
      [Offset(margin, margin), Offset(margin, margin + cornerSize), Offset(margin + cornerSize, margin)],
      // Top right
      [Offset(size.width - margin, margin), Offset(size.width - margin, margin + cornerSize), Offset(size.width - margin - cornerSize, margin)],
      // Bottom left
      [Offset(margin, size.height - margin), Offset(margin, size.height - margin - cornerSize), Offset(margin + cornerSize, size.height - margin)],
      // Bottom right
      [Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - cornerSize), Offset(size.width - margin - cornerSize, size.height - margin)],
    ];
    
    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], paint);
      canvas.drawLine(corner[0], corner[2], paint);
    }
  }
  
  void _drawCrosshair(Canvas canvas, Size size, Paint paint) {
    final centerX = size.width / 2;
    final bottomY = size.height * 0.75;
    const crossSize = 30.0;
    
    // Horizontal line
    canvas.drawLine(
      Offset(centerX - crossSize, bottomY),
      Offset(centerX + crossSize, bottomY),
      paint,
    );
    
    // Vertical line
    canvas.drawLine(
      Offset(centerX, bottomY - crossSize),
      Offset(centerX, bottomY + crossSize),
      paint,
    );
    
    // Circle
    canvas.drawCircle(
      Offset(centerX, bottomY),
      crossSize * 0.6,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(_ARGuidePainter oldDelegate) {
    return oldDelegate.state != state || 
           oldDelegate.stateColor != stateColor;
  }
}

