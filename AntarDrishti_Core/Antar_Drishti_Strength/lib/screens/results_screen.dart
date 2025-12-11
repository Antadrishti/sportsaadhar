import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/jump_result.dart';
import 'home_screen.dart';

/// Results screen displaying the jump analysis
class ResultsScreen extends StatefulWidget {
  final JumpResult result;
  final String videoPath;
  final double heightCm;

  const ResultsScreen({
    super.key,
    required this.result,
    required this.videoPath,
    required this.heightCm,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.videoPath));
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    }
  }

  void _playPauseVideo() {
    if (_videoController == null) return;
    
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _tryAgain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final jumpHeightCm = result.verticalCm;
    final jumpHeightInches = result.verticalInches;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, color: Colors.white),
                      onPressed: _tryAgain,
                    ),
                    const Expanded(
                      child: Text(
                        'Jump Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the row
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Main result card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: result.isValid
                                ? [
                                    const Color(0xFF00D9FF).withOpacity(0.2),
                                    const Color(0xFF00FF88).withOpacity(0.1),
                                  ]
                                : [
                                    Colors.orange.withOpacity(0.2),
                                    Colors.red.withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: result.isValid
                                ? const Color(0xFF00D9FF).withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              result.isValid ? Icons.trending_up : Icons.warning_amber,
                              size: 48,
                              color: result.isValid ? const Color(0xFF00D9FF) : Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              result.isValid ? 'Jump Height' : 'Measurement Issue',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (result.isValid) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    jumpHeightCm?.toStringAsFixed(1) ?? '--',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'cm',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                              if (jumpHeightInches != null)
                                Text(
                                  '(${jumpHeightInches.toStringAsFixed(1)} inches)',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                ),
                            ] else
                              Text(
                                result.flags.isNotEmpty
                                    ? result.flags.first.replaceAll('_', ' ')
                                    : 'Unknown error',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 18,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Confidence indicator
                      _buildInfoCard(
                        'Confidence',
                        result.confidenceLevel,
                        _getConfidenceIcon(result.confidence),
                        _getConfidenceColor(result.confidence),
                      ),

                      const SizedBox(height: 16),

                      // Details grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Your Height',
                              '${widget.heightCm.toStringAsFixed(0)} cm',
                              Icons.person,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Frames',
                              '${result.totalFrames}',
                              Icons.movie,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Flight Time',
                              result.flightTimeS != null
                                  ? '${(result.flightTimeS! * 1000).toStringAsFixed(0)} ms'
                                  : '--',
                              Icons.timer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Scale',
                              result.scaleMPerPx != null
                                  ? '${(result.scaleMPerPx! * 1000).toStringAsFixed(2)} mm/px'
                                  : '--',
                              Icons.straighten,
                            ),
                          ),
                        ],
                      ),

                      // Warning flags
                      if (result.flags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange.withOpacity(0.8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Warnings',
                                    style: TextStyle(
                                      color: Colors.orange.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...result.flags.map((flag) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '• ${flag.replaceAll('_', ' ')}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],

                      // Video playback
                      if (_isVideoInitialized && _videoController != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                                GestureDetector(
                                  onTap: _playPauseVideo,
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to play/pause your recording',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Try again button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _tryAgain,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D9FF),
                            foregroundColor: const Color(0xFF1A1A2E),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFF00D9FF).withOpacity(0.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.7) return Icons.verified;
    if (confidence >= 0.4) return Icons.info_outline;
    return Icons.warning_amber;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return const Color(0xFF00FF88);
    if (confidence >= 0.4) return Colors.amber;
    return Colors.orange;
  }
}
