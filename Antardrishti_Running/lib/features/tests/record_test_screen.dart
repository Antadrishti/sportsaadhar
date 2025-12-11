import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/test_result.dart';
import '../../core/models/user.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/pose_detection_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/video_service.dart';
import '../../main.dart';

class RecordTestScreen extends StatefulWidget {
  const RecordTestScreen({super.key});

  @override
  State<RecordTestScreen> createState() => _RecordTestScreenState();
}

class _RecordTestScreenState extends State<RecordTestScreen> {
  CameraController? _controller;
  Future<void>? _initCameraFuture;
  bool _recording = false;
  bool _processing = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initCameraFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startStopRecording(BuildContext context) async {
    if (_controller == null) return;

    if (!_recording) {
      await _controller!.startVideoRecording();
      setState(() {
        _recording = true;
        _status = 'Recording...';
      });
    } else {
      final file = await _controller!.stopVideoRecording();
      if (!mounted) return;
      setState(() {
        _recording = false;
        _processing = true;
        _status = 'Analyzing performance...';
      });

      await _processVideo(context, File(file.path));
      if (mounted) {
        setState(() {
          _processing = false;
          _status = 'Test saved locally (pending upload).';
        });
      }
    }
  }

  Future<void> _processVideo(BuildContext context, File videoFile) async {
    final videoService = VideoService();
    final localDb = context.read<LocalDbService>();
    final syncService = context.read<SyncService>();
    final poseService = context.read<PoseDetectionService>();
    final appState = context.read<AppState>();

    final User user = appState.user!; // already logged in
    final testName = (ModalRoute.of(context)?.settings.arguments as String?) ??
        'Unknown Test';

    // 1. Save video to app folder
    final savedPath = await videoService.saveVideo(videoFile);

    // 2. Run pose detection (stubbed until MediaPipe/TFLite is wired up)
    PoseAnalysisResult analysis;
    try {
      analysis = await poseService.analyzeVideo(
        videoFile: File(savedPath),
        testName: testName,
      );
    } catch (_) {
      analysis = PoseAnalysisResult.placeholder(testName: testName);
    }

    final result = TestResult(
      id: const Uuid().v4(),
      testTypeId: testName,
      athleteId: user.id,
      createdAt: DateTime.now(),
      videoPath: savedPath,
      metrics: analysis.metrics,
      isValid: analysis.isValid,
      syncStatus: TestSyncStatus.pending,
    );

    await localDb.insertTestResult(result);
    await syncService.syncPendingResults(user);
  }

  @override
  Widget build(BuildContext context) {
    final testName =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 'Selected Test';

    return Scaffold(
      appBar: AppBar(title: Text('Record: $testName')),
      body: _initCameraFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: _initCameraFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    Expanded(
                      child: CameraPreview(_controller!),
                    ),
                    if (_status != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_status!),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _startStopRecording(context),
                        icon: Icon(_recording ? Icons.stop : Icons.fiber_manual_record),
                        label: Text(_recording ? 'Stop & Analyze' : 'Start Recording'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
