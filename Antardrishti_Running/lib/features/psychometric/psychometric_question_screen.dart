import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/psychometric_test.dart';
import '../../core/services/psychometric_service.dart';
import '../../core/services/api_service.dart';
import '../../main.dart';
import 'section_completion_dialog.dart';
import 'psychometric_processing_screen.dart';

/// Psychometric Question Screen - Descriptive text input
class PsychometricQuestionScreen extends StatefulWidget {
  const PsychometricQuestionScreen({super.key});

  @override
  State<PsychometricQuestionScreen> createState() =>
      _PsychometricQuestionScreenState();
}

class _PsychometricQuestionScreenState
    extends State<PsychometricQuestionScreen> {
  int _currentQuestion = 0;
  final List<String> _answers = List.filled(20, '');
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 4 Sections with 5 questions each
  final List<_Section> _sections = [
    _Section(
      id: 'mental_toughness',
      title: 'Mental Toughness',
      icon: Icons.fitness_center,
      color: AppColors.error,
      questions: [
        'Describe a time when you faced a major setback in sports. How did you respond?',
        'How do you handle pressure during competition?',
        'What does mental toughness mean to you?',
        'Tell us about a challenge you overcame through perseverance.',
        'How do you stay motivated when training gets difficult?',
      ],
    ),
    _Section(
      id: 'focus',
      title: 'Focus & Concentration',
      icon: Icons.center_focus_strong,
      color: AppColors.info,
      questions: [
        'How do you maintain focus during long training sessions?',
        'Describe your pre-competition mental preparation routine.',
        'What techniques do you use to block out distractions?',
        'How do you refocus after making a mistake?',
        'What helps you concentrate best during competition?',
      ],
    ),
    _Section(
      id: 'stress',
      title: 'Stress Management',
      icon: Icons.spa,
      color: AppColors.success,
      questions: [
        'How do you manage pre-competition anxiety?',
        'Describe a technique you use to stay calm under pressure.',
        'What stresses you out most in competitive situations?',
        'How do you recover mentally after a poor performance?',
        'What helps you relax before an important event?',
      ],
    ),
    _Section(
      id: 'teamwork',
      title: 'Team Collaboration',
      icon: Icons.people,
      color: AppColors.primaryOrange,
      questions: [
        'How do you support teammates when they\'re struggling?',
        'Describe a time when teamwork led to success.',
        'How do you handle conflicts within a team?',
        'What makes you a good teammate?',
        'How do you balance individual goals with team objectives?',
      ],
    ),
  ];

  int get _currentSection => _currentQuestion ~/ 5;
  int get _questionInSection => _currentQuestion % 5;

  @override
  void initState() {
    super.initState();
    // Load the first question's saved answer if any
    _answerController.text = _answers[_currentQuestion];
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _nextQuestion() async {
    // Save current answer
    _answers[_currentQuestion] = _answerController.text.trim();

    // Check if we've completed a section (questions 4, 9, 14, 19)
    final isEndOfSection = (_currentQuestion + 1) % 5 == 0;
    final sectionNumber = _currentSection + 1;

    if (_currentQuestion < 19) {
      if (isEndOfSection) {
        // Show section completion dialog
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => SectionCompletionDialog(
            sectionNumber: sectionNumber,
            totalSections: 4,
            sectionTitle: _sections[_currentSection].title,
            sectionIcon: _sections[_currentSection].icon,
            sectionColor: _sections[_currentSection].color,
          ),
        );

        if (shouldContinue != true && mounted) {
          return;
        }
      }

      // Move to next question
      setState(() {
        _currentQuestion++;
        _answerController.text = _answers[_currentQuestion];
      });

      // Refocus after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } else {
      // Submit all answers
      await _submitTest();
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      // Save current answer
      _answers[_currentQuestion] = _answerController.text.trim();

      setState(() {
        _currentQuestion--;
        _answerController.text = _answers[_currentQuestion];
      });
    }
  }

  Future<void> _submitTest() async {
    final appState = context.read<AppState>();
    final user = appState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit test')),
      );
      return;
    }

    // Build answers list
    final List<PsychometricAnswer> answers = [];
    for (int i = 0; i < 20; i++) {
      final sectionIndex = i ~/ 5;
      final questionIndex = i % 5;
      final section = _sections[sectionIndex];

      answers.add(PsychometricAnswer(
        section: section.id,
        questionId: questionIndex + 1,
        question: section.questions[questionIndex],
        answer: _answers[i],
      ));
    }

    // Navigate to processing screen
    if (mounted) {
      final apiService = context.read<ApiService>();
      final psychometricService = PsychometricService(apiService);
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PsychometricProcessingScreen(
            answers: answers,
            psychometricService: psychometricService,
          ),
        ),
      );
    }
  }

  bool get _canProceed {
    final currentAnswer = _answerController.text.trim();
    return currentAnswer.length >= 20; // Minimum 20 characters
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_currentSection];
    final question = section.questions[_questionInSection];
    final progress = (_currentQuestion + 1) / 20;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            _buildProgressHeader(section, progress),

            // Question Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildQuestionCard(section, question),
                    const SizedBox(height: 24),
                    _buildAnswerField(),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            _buildNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(_Section section, double progress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPurple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Row(
            children: [
              IconButton(
                onPressed: () => _showExitDialog(context),
                icon: const Icon(Icons.close),
                color: AppColors.lightTextSecondary,
              ),
              const Spacer(),
              // Section Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(section.icon, size: 14, color: section.color),
                    const SizedBox(width: 6),
                    Text(
                      section.title,
                      style: AppTypography.labelSmall.copyWith(
                        color: section.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_currentQuestion + 1}/20',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.achievementMental,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(_Section section, String question) {
    return Container(
      key: ValueKey(_currentQuestion),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            section.color.withValues(alpha: 0.1),
            section.color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: section.color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              section.icon,
              size: 28,
              color: section.color,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Question ${_questionInSection + 1} of 5',
            style: AppTypography.labelMedium.copyWith(
              color: section.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            question,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.lightTextPrimary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate(key: ValueKey('q_$_currentQuestion'))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05);
  }

  Widget _buildAnswerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Answer',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _canProceed
                  ? AppColors.achievementMental
                  : AppColors.lightBorder,
              width: _canProceed ? 2 : 1,
            ),
            boxShadow: [
              if (_canProceed)
                BoxShadow(
                  color: AppColors.achievementMental.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: TextField(
            controller: _answerController,
            focusNode: _focusNode,
            maxLines: 8,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Share your thoughts... (minimum 20 characters)',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '${_answerController.text.length}/1000',
              counterStyle: AppTypography.labelSmall.copyWith(
                color: _canProceed
                    ? AppColors.achievementMental
                    : AppColors.lightTextSecondary,
              ),
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.lightTextPrimary,
              height: 1.5,
            ),
            onChanged: (value) {
              setState(() {}); // Rebuild to update button state
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryPurple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          if (_currentQuestion > 0)
            TextButton.icon(
              onPressed: _previousQuestion,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lightTextSecondary,
              ),
            )
          else
            const SizedBox(width: 80),

          const Spacer(),

          // Next Button
          ElevatedButton(
            onPressed: _canProceed ? _nextQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.achievementMental,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.gray300,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _currentQuestion == 19 ? 'Finish' : 'Next',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentQuestion == 19 ? Icons.check : Icons.arrow_forward,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Exit Assessment?'),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> questions;

  const _Section({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.questions,
  });
}
