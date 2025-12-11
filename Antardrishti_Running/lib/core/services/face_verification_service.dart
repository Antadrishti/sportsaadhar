import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/face_verification_result.dart';
import 'face_embedding_service.dart';

/// Service for performing 1:1 face verification using embeddings.
///
/// This service uses TensorFlow Lite face recognition models to generate
/// face embeddings and compare them using cosine similarity.
///
/// Features:
/// - Detects faces in reference image and video frames
/// - Generates face embeddings using TFLite model
/// - Compares embeddings using cosine similarity
/// - Provides accurate face matching with confidence scores
class FaceVerificationService {
  bool _initialized = false;
  late FaceDetector _faceDetector;
  late FaceEmbeddingService _embeddingService;
  static const double _defaultThreshold = 0.6; // Cosine similarity threshold

  /// Initialize the service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔧 FaceVerificationService: Initializing...');
      
      // Initialize face detector
      final options = FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.15, // Minimum 15% of image for better detection
        performanceMode: FaceDetectorMode.accurate,
      );
      
      _faceDetector = FaceDetector(options: options);
      
      // Initialize face embedding service
      _embeddingService = FaceEmbeddingService();
      await _embeddingService.initialize();
      
      _initialized = true;
      debugPrint('✅ FaceVerificationService: Initialized successfully');
    } catch (e) {
      debugPrint('❌ FaceVerificationService: Initialization failed: $e');
      throw Exception('Failed to initialize FaceVerificationService: $e');
    }
  }

  /// Verify face using embedding-based comparison.
  ///
  /// This method generates embeddings for the reference image and video frames,
  /// then compares them using cosine similarity for accurate face matching.
  /// Returns match if ANY frame exceeds the threshold (70%).
  Future<FaceVerificationResult> verifyFace({
    required String referenceImagePath,
    required String videoPath,
    double threshold = _defaultThreshold,
    int sampleFrames = 5, // Default to 5 frames
  }) async {
    await initialize();

    try {
      debugPrint('🔍 Starting face verification with embeddings...');
      debugPrint('📸 Reference image: $referenceImagePath');
      debugPrint('🎥 Video path: $videoPath');
      debugPrint('🎯 Threshold: ${(threshold * 100).toStringAsFixed(1)}%');

      // Validate file paths
      final referenceImageFile = File(referenceImagePath);
      final videoFile = File(videoPath);

      if (!await referenceImageFile.exists()) {
        return FaceVerificationResult.error(
          errorMessage: 'Reference image not found at: $referenceImagePath',
        );
      }

      if (!await videoFile.exists()) {
        return FaceVerificationResult.error(
          errorMessage: 'Video file not found at: $videoPath',
        );
      }

      // Step 1: Generate embedding for reference image
      debugPrint('📷 Generating embedding for reference image...');
      final referenceEmbedding = await _embeddingService.generateEmbedding(referenceImagePath);
      
      if (referenceEmbedding == null) {
        return FaceVerificationResult.error(
          errorMessage: 'No face detected in reference image. Please use a clear front-facing photo.',
          debugData: {'step': 'reference_embedding_generation'},
        );
      }

      debugPrint('✅ Reference embedding generated (${referenceEmbedding.length} dimensions)');

      // Step 2: Extract frames from video and generate embeddings
      debugPrint('🎬 Processing video frames...');
      final frameResults = await _processVideoFrames(
        videoPath,
        sampleFrames: sampleFrames,
      );

      if (frameResults.isEmpty) {
        return FaceVerificationResult.noMatch(
          confidenceScore: 0.0,
          threshold: threshold,
          facesDetected: 0,
          framesProcessed: sampleFrames,
          debugData: {'step': 'video_processing', 'message': 'No faces detected in video'},
        );
      }

      debugPrint('✅ Generated ${frameResults.length} embeddings from video frames');

      // Step 3: Compare embeddings using cosine similarity
      debugPrint('🔬 Comparing embeddings...');
      final similarities = <double>[];
      
      for (int i = 0; i < frameResults.length; i++) {
        final embedding = frameResults[i];
        final similarity = _embeddingService.cosineSimilarity(referenceEmbedding, embedding);
        similarities.add(similarity);
        debugPrint('   Frame ${i + 1}: similarity = ${(similarity * 100).toStringAsFixed(1)}%');
      }

      // Calculate average and max similarity
      final avgSimilarity = similarities.reduce((a, b) => a + b) / similarities.length;
      final maxSimilarity = similarities.reduce((a, b) => a > b ? a : b);
      
      // Use max similarity as confidence (best match across frames)
      // Match if ANY frame exceeds threshold
      final confidence = maxSimilarity;
      final isMatch = confidence >= threshold;

      debugPrint('✅ Verification complete: ${isMatch ? "MATCH ✓" : "NO MATCH ✗"}');
      debugPrint('📊 Max Similarity: ${(maxSimilarity * 100).toStringAsFixed(1)}%');
      debugPrint('📊 Avg Similarity: ${(avgSimilarity * 100).toStringAsFixed(1)}%');
      debugPrint('📊 Threshold: ${(threshold * 100).toStringAsFixed(1)}%');
      debugPrint('📊 Decision: ${isMatch ? "Any frame passed threshold" : "No frame passed threshold"}');

      return isMatch
          ? FaceVerificationResult.match(
              confidenceScore: confidence,
              threshold: threshold,
              facesDetected: frameResults.length,
              framesProcessed: sampleFrames,
              debugData: {
                'method': 'embedding_comparison',
                'maxSimilarity': maxSimilarity,
                'avgSimilarity': avgSimilarity,
                'embeddingSize': referenceEmbedding.length,
                'similarities': similarities,
              },
            )
          : FaceVerificationResult.noMatch(
              confidenceScore: confidence,
              threshold: threshold,
              facesDetected: frameResults.length,
              framesProcessed: sampleFrames,
              debugData: {
                'method': 'embedding_comparison',
                'maxSimilarity': maxSimilarity,
                'avgSimilarity': avgSimilarity,
                'embeddingSize': referenceEmbedding.length,
                'similarities': similarities,
              },
            );

    } catch (e, stackTrace) {
      debugPrint('❌ Face verification error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return FaceVerificationResult.error(
        errorMessage: 'Verification failed: ${e.toString()}',
        debugData: {'exception': e.toString(), 'stackTrace': stackTrace.toString()},
      );
    }
  }

  /// Process video frames and generate embeddings.
  Future<List<List<double>>> _processVideoFrames(
    String videoPath, {
    required int sampleFrames,
  }) async {
    List<String> framePaths = [];
    List<List<double>> embeddings = [];
    
    try {
      debugPrint('🎥 Extracting frames from video...');
      
      // Get video duration
      final videoController = VideoPlayerController.file(File(videoPath));
      await videoController.initialize();
      final duration = videoController.value.duration;
      await videoController.dispose();
      
      if (duration.inMilliseconds == 0) {
        debugPrint('❌ Video has zero duration');
        return [];
      }

      debugPrint('📹 Video duration: ${duration.inSeconds}s');
      
      // Extract 5 frames from first 5 seconds of video ONLY
      // This ensures we capture the face clearly at the start
      final maxDuration = math.min(5000, duration.inMilliseconds); // First 5 seconds max
      final actualSampleFrames = math.min(sampleFrames, 5); // Max 5 frames
      
      // Space frames evenly across first 5 seconds
      final frameInterval = maxDuration ~/ (actualSampleFrames + 1);
      
      debugPrint('📸 Extracting $actualSampleFrames frames from first ${(maxDuration / 1000).toStringAsFixed(1)}s');
      
      // Create temp directory for frames
      final tempDir = await getTemporaryDirectory();
      final framesDir = Directory(path.join(
        tempDir.path, 
        'video_frames_${DateTime.now().millisecondsSinceEpoch}'
      ));
      await framesDir.create(recursive: true);
      
      // Extract frames from first 5 seconds
      for (int i = 1; i <= actualSampleFrames; i++) {
        final timestampMs = (i * frameInterval).round();
        final framePath = path.join(framesDir.path, 'frame_$i.jpg');
        
        try {
          final uint8list = await VideoThumbnail.thumbnailData(
            video: videoPath,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 1280, // Higher resolution for better quality
            quality: 95,    // Higher quality
            timeMs: timestampMs,
          );
          
          if (uint8list != null) {
            final file = File(framePath);
            await file.writeAsBytes(uint8list);
            framePaths.add(framePath);
            
            // Generate embedding for frame
            final embedding = await _embeddingService.generateEmbedding(framePath);
            
            if (embedding != null) {
              embeddings.add(embedding);
              debugPrint('✅ Generated embedding for frame $i at ${(timestampMs / 1000).toStringAsFixed(1)}s');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error processing frame $i: $e');
        }
      }
      
      debugPrint('✅ Generated ${embeddings.length} embeddings across ${framePaths.length} frames');
      return embeddings;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error processing video frames: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    } finally {
      // Clean up frame files
      for (final framePath in framePaths) {
        try {
          final file = File(framePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('⚠️ Failed to delete frame file: $framePath');
        }
      }
      
      if (framePaths.isNotEmpty) {
        try {
          final framesDir = Directory(path.dirname(framePaths.first));
          if (await framesDir.exists()) {
            await framesDir.delete(recursive: true);
          }
        } catch (e) {
          debugPrint('⚠️ Failed to delete frames directory: $e');
        }
      }
    }
  }


  /// Dispose resources.
  Future<void> dispose() async {
    if (_initialized) {
      await _faceDetector.close();
      await _embeddingService.dispose();
      _initialized = false;
    }
  }
}

/// Extension to add copyWith method to FaceVerificationResult.
extension FaceVerificationResultExtension on FaceVerificationResult {
  FaceVerificationResult copyWith({
    bool? isMatch,
    double? confidenceScore,
    double? threshold,
    int? facesDetected,
    int? framesProcessed,
    String? errorMessage,
    Map<String, dynamic>? debugData,
  }) {
    return FaceVerificationResult(
      isMatch: isMatch ?? this.isMatch,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      threshold: threshold ?? this.threshold,
      facesDetected: facesDetected ?? this.facesDetected,
      framesProcessed: framesProcessed ?? this.framesProcessed,
      errorMessage: errorMessage ?? this.errorMessage,
      debugData: debugData ?? this.debugData,
    );
  }
}
