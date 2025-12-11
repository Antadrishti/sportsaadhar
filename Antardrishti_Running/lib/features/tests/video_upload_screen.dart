import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/test_result.dart';
import '../../core/models/user.dart';
import '../../core/services/local_db_service.dart';
import '../../core/services/pose_detection_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/video_service.dart';
import '../../main.dart';
import 'data/demo_tests.dart';

class VideoUploadScreen extends StatefulWidget {
  const VideoUploadScreen({super.key});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _saving = false;
  String? _status;
  String _selectedTest = demoTests.first.name;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    final controller = VideoPlayerController.file(File(picked.path));
    await controller.initialize();
    controller
      ..setLooping(true)
      ..setVolume(0)
      ..play();

    final oldController = _videoController;
    setState(() {
      _selectedVideo = picked;
      _videoController = controller;
      _status = 'Preview ready. Upload when satisfied.';
    });
    oldController?.dispose();
  }

  Future<void> _saveVideo(BuildContext context) async {
    if (_selectedVideo == null) {
      setState(() => _status = 'Pick a video first.');
      return;
    }

    final appState = context.read<AppState>();
    final User? user = appState.user;
    if (user == null) {
      setState(() => _status = 'Please login again to upload videos.');
      return;
    }

    setState(() {
      _saving = true;
      _status = 'Saving video for offline processing...';
    });

    try {
      final videoService = VideoService();
      final localDb = context.read<LocalDbService>();
      final syncService = context.read<SyncService>();
      final poseService = context.read<PoseDetectionService>();

      final savedPath = await videoService.saveVideo(File(_selectedVideo!.path));

      PoseAnalysisResult analysis;
      try {
        analysis = await poseService.analyzeVideo(
          videoFile: File(savedPath),
          testName: _selectedTest,
        );
      } catch (_) {
        analysis = PoseAnalysisResult.placeholder(testName: _selectedTest);
      }

      final result = TestResult(
        id: const Uuid().v4(),
        testTypeId: _selectedTest,
        athleteId: user.id,
        createdAt: DateTime.now(),
        videoPath: savedPath,
        metrics: {
          'source': 'uploaded_video',
          'file_name': _selectedVideo!.name,
          ...analysis.metrics,
        },
        isValid: analysis.isValid,
        syncStatus: TestSyncStatus.pending,
      );

      await localDb.insertTestResult(result);
      await syncService.syncPendingResults(user);

      final oldController = _videoController;
      setState(() {
        _status = 'Video processed locally. Ready for sync.';
        _selectedVideo = null;
        _videoController = null;
      });
      oldController?.dispose();
    } catch (e) {
      setState(() => _status = 'Unable to save video: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Test Video'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '1. Choose test type',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedTest,
              items: demoTests
                  .map((test) => DropdownMenuItem(
                        value: test.name,
                        child: Text(test.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTest = value);
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              '2. Pick a video file',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickVideo,
              icon: const Icon(Icons.video_library_outlined),
              label: Text(_selectedVideo == null ? 'Select from gallery' : 'Choose another video'),
            ),
            const SizedBox(height: 12),
            if (_videoController != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio == 0
                        ? 16 / 9
                        : _videoController!.value.aspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedVideo?.name ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: const Center(
                  child: Text('Video preview will appear here'),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : () => _saveVideo(context),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_saving ? 'Saving...' : 'Save & Queue for Analysis'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
