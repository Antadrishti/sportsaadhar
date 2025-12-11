import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Service for generating face embeddings using TensorFlow Lite.
///
/// This service uses the MobileFaceNet model to generate 192-dimensional embeddings
/// from face images. These embeddings are then compared using cosine similarity
/// for accurate face matching.
class FaceEmbeddingService {
  late Interpreter _interpreter;
  bool _initialized = false;
  
  // Model configuration
  static const String _modelPath = 'assets/models/mobile_face_net.tflite';
  static const int _inputSize = 112; // MobileFaceNet uses 112x112 input
  static const int _embeddingSize = 192; // MobileFaceNet outputs 192-dim embeddings
  
  // Face detector for preprocessing
  late FaceDetector _faceDetector;
  
  /// Initialize the TFLite model and face detector.
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      debugPrint('🔧 FaceEmbeddingService: Initializing...');
      
      // Initialize face detector for preprocessing
      final options = FaceDetectorOptions(
        enableClassification: false,
        enableLandmarks: true,
        enableContours: false,
        enableTracking: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      );
      _faceDetector = FaceDetector(options: options);
      
      // Load TFLite model (required)
      try {
        _interpreter = await Interpreter.fromAsset(_modelPath);
        debugPrint('✅ TFLite model loaded successfully');
        debugPrint('   Input shape: ${_interpreter.getInputTensors()}');
        debugPrint('   Output shape: ${_interpreter.getOutputTensors()}');
      } catch (e) {
        debugPrint('❌ Failed to load TFLite model from: $_modelPath');
        debugPrint('   Error: $e');
        throw Exception('TFLite model is required but could not be loaded. Please ensure mobile_face_net.tflite exists in assets/models/');
      }
      
      _initialized = true;
      debugPrint('✅ FaceEmbeddingService: Initialized successfully');
    } catch (e) {
      debugPrint('❌ FaceEmbeddingService: Initialization failed: $e');
      throw Exception('Failed to initialize FaceEmbeddingService: $e');
    }
  }
  
  /// Generate face embedding from an image file.
  ///
  /// Returns a list of doubles representing the face embedding,
  /// or null if no face is detected or an error occurs.
  Future<List<double>?> generateEmbedding(String imagePath) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      debugPrint('📸 Generating embedding for: $imagePath');
      
      // Read image file
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('❌ Image file not found: $imagePath');
        return null;
      }
      
      // Detect face in image
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        debugPrint('❌ No face detected in image');
        return null;
      }
      
      final face = faces.first;
      debugPrint('✅ Face detected: ${face.boundingBox}');
      
      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        debugPrint('❌ Failed to decode image');
        return null;
      }
      
      // Crop face region with padding
      final bbox = face.boundingBox;
      final padding = (bbox.width * 0.2).toInt(); // 20% padding
      final left = math.max(0, bbox.left.toInt() - padding);
      final top = math.max(0, bbox.top.toInt() - padding);
      final width = math.min(image.width - left, bbox.width.toInt() + 2 * padding);
      final height = math.min(image.height - top, bbox.height.toInt() + 2 * padding);
      
      img.Image faceImage = img.copyCrop(
        image,
        x: left,
        y: top,
        width: width,
        height: height,
      );
      
      // Align face if landmarks are available
      faceImage = _alignFace(faceImage, face);
      
      // Generate embedding using TFLite model
      final embedding = await _generateEmbeddingWithTFLite(faceImage);
      
      debugPrint('✅ Embedding generated: ${embedding.length} dimensions');
      return embedding;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error generating embedding: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Generate embedding using TFLite model.
  Future<List<double>> _generateEmbeddingWithTFLite(img.Image faceImage) async {
    // Resize to model input size
    final resized = img.copyResize(
      faceImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );
    
    // Normalize pixel values to [-1, 1] or [0, 1] depending on model
    final input = _preprocessImage(resized);
    
    // Prepare output buffer
    final output = List.filled(_embeddingSize, 0.0);
    final outputBuffer = [output];
    
    // Run inference
    _interpreter.run(input, outputBuffer);
    
    // Extract and normalize embedding
    final embedding = outputBuffer[0].cast<double>();
    return _normalizeEmbedding(embedding);
  }
  
  /// Preprocess image for TFLite model input.
  /// MobileFaceNet expects input normalized to [0, 1] range in RGB format.
  List _preprocessImage(img.Image image) {
    // Convert to float32 array with normalization [0, 1]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // Normalize to [0, 1] range - MobileFaceNet standard
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return input;
  }
  
  /// Align face using facial landmarks if available.
  img.Image _alignFace(img.Image faceImage, Face face) {
    try {
      // Check if landmarks are available
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      
      if (leftEye == null || rightEye == null) {
        return faceImage; // No alignment possible
      }
      
      // Calculate rotation angle based on eye positions
      final dx = rightEye.position.x - leftEye.position.x;
      final dy = rightEye.position.y - leftEye.position.y;
      final angle = math.atan2(dy, dx) * 180 / math.pi;
      
      // Only rotate if angle is significant (more than 5 degrees)
      if (angle.abs() > 5) {
        return img.copyRotate(faceImage, angle: -angle);
      }
      
      return faceImage;
    } catch (e) {
      debugPrint('⚠️ Could not align face: $e');
      return faceImage;
    }
  }
  
  /// Normalize embedding vector to unit length (L2 normalization).
  List<double> _normalizeEmbedding(List<double> embedding) {
    double norm = 0;
    for (final value in embedding) {
      norm += value * value;
    }
    norm = math.sqrt(norm);
    
    if (norm < 1e-10) {
      return embedding; // Avoid division by zero
    }
    
    return embedding.map((value) => value / norm).toList();
  }
  
  /// Calculate cosine similarity between two embeddings.
  ///
  /// Returns a value between -1 and 1, where:
  /// - 1.0 means identical embeddings (perfect match)
  /// - 0.0 means orthogonal embeddings (no similarity)
  /// - -1.0 means opposite embeddings (very dissimilar)
  double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }
    
    double dotProduct = 0;
    double norm1 = 0;
    double norm2 = 0;
    
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }
    
    norm1 = math.sqrt(norm1);
    norm2 = math.sqrt(norm2);
    
    if (norm1 < 1e-10 || norm2 < 1e-10) {
      return 0.0; // Avoid division by zero
    }
    
    return dotProduct / (norm1 * norm2);
  }
  
  /// Calculate Euclidean distance between two embeddings.
  ///
  /// Returns a value >= 0, where:
  /// - 0.0 means identical embeddings
  /// - Larger values mean more dissimilar embeddings
  double euclideanDistance(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }
    
    double sum = 0;
    for (int i = 0; i < embedding1.length; i++) {
      final diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }
    
    return math.sqrt(sum);
  }
  
  /// Dispose resources.
  Future<void> dispose() async {
    if (_initialized) {
      _interpreter.close();
      await _faceDetector.close();
      _initialized = false;
      debugPrint('✅ FaceEmbeddingService: Disposed');
    }
  }
}

