/// Psychometric test models

/// Single answer in a psychometric test
class PsychometricAnswer {
  final String section;
  final int questionId;
  final String question;
  final String answer;

  const PsychometricAnswer({
    required this.section,
    required this.questionId,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() => {
        'section': section,
        'questionId': questionId,
        'question': question,
        'answer': answer,
      };

  factory PsychometricAnswer.fromJson(Map<String, dynamic> json) {
    return PsychometricAnswer(
      section: json['section'] as String,
      questionId: json['questionId'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}

/// Psychometric test result
class PsychometricResult {
  final String id;
  final int overallScore;
  final Map<String, int> sectionScores;
  final DateTime completedAt;
  final String analysisStatus;
  final bool alreadyCompleted;

  const PsychometricResult({
    required this.id,
    required this.overallScore,
    required this.sectionScores,
    required this.completedAt,
    this.analysisStatus = 'pending',
    this.alreadyCompleted = false,
  });

  factory PsychometricResult.fromJson(Map<String, dynamic> json) {
    final sectionScoresJson = json['sectionScores'] as Map<String, dynamic>?;
    final sectionScores = <String, int>{};
    
    if (sectionScoresJson != null) {
      sectionScoresJson.forEach((key, value) {
        sectionScores[key] = (value is int) ? value : (value as num).toInt();
      });
    }

    return PsychometricResult(
      id: json['id'] as String,
      overallScore: json['overallScore'] as int,
      sectionScores: sectionScores,
      completedAt: DateTime.parse(json['completedAt'] as String),
      analysisStatus: json['analysisStatus'] as String? ?? 'pending',
      alreadyCompleted: json['alreadyCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'overallScore': overallScore,
        'sectionScores': sectionScores,
        'completedAt': completedAt.toIso8601String(),
        'analysisStatus': analysisStatus,
        'alreadyCompleted': alreadyCompleted,
      };
}

/// Section data for UI
class PsychometricSection {
  final String id;
  final String title;
  final String icon;
  final int color;
  final List<String> questions;

  const PsychometricSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.questions,
  });
}


