import 'dart:convert';

enum TestSyncStatus { pending, uploaded, failed }

class TestResult {
  final String id;
  final String testTypeId;
  final String athleteId;
  final DateTime createdAt;
  final String videoPath; // local file path
  final Map<String, dynamic> metrics; // e.g. { "jump_height_cm": 52 }
  final bool isValid;
  final TestSyncStatus syncStatus;

  TestResult({
    required this.id,
    required this.testTypeId,
    required this.athleteId,
    required this.createdAt,
    required this.videoPath,
    required this.metrics,
    required this.isValid,
    required this.syncStatus,
  });

  factory TestResult.fromMap(Map<String, dynamic> map) => TestResult(
        id: map['id'] as String,
        testTypeId: map['testTypeId'] as String,
        athleteId: map['athleteId'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        videoPath: map['videoPath'] as String,
        metrics: _parseMetrics(map['metrics']),
        isValid: map['isValid'] == 1 || map['isValid'] == true,
        syncStatus: TestSyncStatus.values[map['syncStatus'] ?? 0],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'testTypeId': testTypeId,
        'athleteId': athleteId,
        'createdAt': createdAt.toIso8601String(),
        'videoPath': videoPath,
        'metrics': jsonEncode(metrics),
        'isValid': isValid ? 1 : 0,
        'syncStatus': syncStatus.index,
      };

  static Map<String, dynamic> _parseMetrics(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) {
      return Map<String, dynamic>.from(
          raw.map((key, value) => MapEntry(key.toString(), value)));
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(
              decoded.map((key, value) => MapEntry(key.toString(), value)));
        }
      } catch (_) {
        return {};
      }
    }
    return {};
  }
}
