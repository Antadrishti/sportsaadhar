import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/psychometric_test.dart';
import '../../core/services/psychometric_service.dart';
import 'psychometric_result_screen.dart';

/// Processing Screen - Shows while analyzing responses and submitting to backend
class PsychometricProcessingScreen extends StatefulWidget {
  final List<PsychometricAnswer> answers;
  final PsychometricService psychometricService;

  const PsychometricProcessingScreen({
    super.key,
    required this.answers,
    required this.psychometricService,
  });

  @override
  State<PsychometricProcessingScreen> createState() =>
      _PsychometricProcessingScreenState();
}

class _PsychometricProcessingScreenState
    extends State<PsychometricProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  bool _hasError = false;
  String? _errorMessage;

  final List<_ProcessStep> _steps = [
    _ProcessStep('Collecting responses...', Icons.cloud_download),
    _ProcessStep('Analyzing patterns...', Icons.psychology),
    _ProcessStep('Calculating scores...', Icons.calculate),
    _ProcessStep('Generating insights...', Icons.lightbulb),
    _ProcessStep('Preparing your results...', Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _simulateProcessingAndSubmit();
  }

  void _simulateProcessingAndSubmit() async {
    try {
      // Animate through processing steps
      for (int i = 0; i < _steps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() => _currentStep = i);
        }
      }

      // Submit to backend
      final result = await widget.psychometricService.submitTest(widget.answers);

      // Navigate to results after processing
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PsychometricResultScreen(
              result: result['result'] as PsychometricResult,
              xpEarned: result['xpEarned'] as int,
              levelUp: result['levelUp'],
              unlockedAchievements: result['unlockedAchievements'] as List,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Submission Failed',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'An error occurred',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Brain
                _buildAnimatedBrain(),

                const SizedBox(height: 48),

                // Processing Steps
                _buildProcessingSteps(),

                const SizedBox(height: 48),

                // Progress Dots
                _buildProgressDots(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBrain() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow Ring 1
            Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.achievementMental.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
            ),

            // Outer Glow Ring 2
            Transform.rotate(
              angle: -_controller.value * 2 * math.pi,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryOrange.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),

            // Pulsing Glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 120 + (math.sin(_controller.value * 2 * math.pi) * 10),
              height: 120 + (math.sin(_controller.value * 2 * math.pi) * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.achievementMental.withValues(alpha: 0.3),
                    AppColors.achievementMental.withValues(alpha: 0),
                  ],
                ),
              ),
            ),

            // Brain Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.achievementMental,
                    AppColors.secondaryPurple,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.achievementMental.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🧠', style: TextStyle(fontSize: 45)),
              ),
            ),

            // Floating Particles
            ..._buildParticles(),
          ],
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(8, (index) {
      final angle = (index / 8) * 2 * math.pi + _controller.value * 2 * math.pi;
      final radius = 90.0;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      return Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index % 2 == 0
                ? AppColors.primaryOrange
                : AppColors.achievementMental,
          ),
        ),
      );
    });
  }

  Widget _buildProcessingSteps() {
    return Column(
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: index <= _currentStep ? 1.0 : 0.3,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.achievementMental
                            : AppColors.gray300,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: AppColors.white)
                        : isActive
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Icon(step.icon, size: 14, color: AppColors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  step.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isActive
                        ? AppColors.achievementMental
                        : isDone
                            ? AppColors.success
                            : AppColors.lightTextSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (index) {
        final isActive = index <= _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppColors.achievementMental : AppColors.gray300,
          ),
        );
      }),
    );
  }
}

class _ProcessStep {
  final String text;
  final IconData icon;

  const _ProcessStep(this.text, this.icon);
}
