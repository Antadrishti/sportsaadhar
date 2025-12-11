import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  GenerativeModel? _model;

  void _initModel() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    // Using gemini-2.5-flash as per documentation.
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
    );
  }

  Future<String> analyzeHeight(File mediaFile, {bool isVideo = true}) async {
    try {
      if (_model == null) {
        _initModel();
      }

      final mediaBytes = await mediaFile.readAsBytes();
      final mimeType = isVideo ? 'video/mp4' : 'image/jpeg'; // Simplification for now, consider MIME detection if needed
      
      final prompt = '''
Strictly validate the image before analyzing height. 
1. **Validation Checks (Cheat Detection):**
   - Reject if the person is sitting, crouching, or lying down.
   - Reject if the full body is not visible (head to feet).
   - Reject if the person is too far or obstructed.
   - Reject if not standing upright (straight posture).
   - Reject if no reliable reference object (door, chair, etc.) is visible.
   - If ANY check fails, return exactly: "ERROR: Upload a full-body standing image with the person clearly visible from head to feet and at least one reference object." and stop.

2. **Height Estimation (Only if valid):**
   - Use reference objects and body proportions to estimate height.
   - Return ONLY the result in this exact format: "Height: XX cm"
   - Do NOT provide a range (e.g., 170-175 cm). Pick the single most likely number.
   - Do NOT provide any other text, reasoning, or markdown.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, mediaBytes),
        ])
      ];

      final response = await _model!.generateContent(content);
      return response.text ?? 'Could not analyze media.';
    } catch (e) {
      print('Error calling Gemini: $e');
      return 'Error: $e';
    }
  }
}
