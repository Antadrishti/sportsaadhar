import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({super.key});

  @override
  State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _result;
  bool _isPhoto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['mode'] == 'photo') {
      setState(() {
        _isPhoto = true;
      });
    }
  }

  Future<void> _handleCapture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isPhoto) {
      if (_isProcessing) return;
      
      try {
        setState(() => _isProcessing = true);
        final file = await _controller!.takePicture();
        await _analyzeMedia(File(file.path), isVideo: false);
      } catch (e) {
         print('Error taking picture: $e');
         setState(() {
           _isProcessing = false;
           _result = 'Error taking picture: $e';
         });
      }
    } else {
      _toggleRecording();
    }
  }

  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _initializeController(_cameras![_selectedCameraIndex]);
    }
  }

  Future<void> _initializeController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg, 
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _controller?.dispose();
    await _initializeController(_cameras![_selectedCameraIndex]);
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      try {
        final file = await _controller!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _isProcessing = true;
        });
        await _analyzeMedia(File(file.path), isVideo: true);
      } catch (e) {
        print('Error stopping recording: $e');
        setState(() {
          _isRecording = false;
          _result = 'Error stopping recording: $e';
        });
      }
    } else {
      try {
        await _controller!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _result = null;
        });
      } catch (e) {
         print('Error starting recording: $e');
         setState(() {
           _result = 'Error starting recording: $e';
         });
      }
    }
  }

  Future<void> _analyzeMedia(File mediaFile, {required bool isVideo}) async {
    try {
      final result = await GeminiService().analyzeHeight(mediaFile, isVideo: isVideo);
      
      // Parse and save latest height
      if (result.startsWith('Height:')) {
         final heightStr = result.replaceAll('Height:', '').replaceAll('cm', '').trim();
         final height = double.tryParse(heightStr);
         if (height != null) {
           // Save locally
           final prefs = await SharedPreferences.getInstance();
           await prefs.setDouble('max_height', height);
           
           // Submit to backend API
           await ApiService.submitTestResult(
             testName: 'Height Measurement',
             value: height,
             unit: 'cm',
             notes: 'Measured via Gemini AI',
           );
         }
      }

      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      appBar: AppBar(title: Text(_isPhoto ? 'Take Photo' : 'Record Video')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          if (_result != null)
            AlertDialog(
              title: const Text('Analysis Result'),
              content: SingleChildScrollView(child: Text(_result!)), // Added scroll
              actions: [
                TextButton(
                  onPressed: () => setState(() => _result = null),
                  child: const Text('Close'),
                ),
              ],
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   FloatingActionButton(
                    heroTag: 'flip',
                    onPressed: _toggleCamera,
                    child: const Icon(Icons.flip_camera_ios),
                  ),
                  FloatingActionButton(
                    heroTag: 'record',
                    backgroundColor: _isPhoto ? Colors.blue : (_isRecording ? Colors.red : Colors.blue),
                    onPressed: _handleCapture,
                    child: Icon(_isPhoto ? Icons.camera_alt : (_isRecording ? Icons.stop : Icons.videocam)),
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
