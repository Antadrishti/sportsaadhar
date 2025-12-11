import 'package:flutter/material.dart';
import '../../../core/models/physical_test.dart';

class TestCard extends StatelessWidget {
  final PhysicalTest test;
  final bool isEnabled;
  final VoidCallback? onStartTest;

  const TestCard({
    super.key,
    required this.test,
    required this.isEnabled,
    this.onStartTest,
  });

  Color get _iconBackgroundColor {
    switch (test.category) {
      case TestCategory.measurement:
        return const Color(0xFFE8F5E9);
      case TestCategory.flexibility:
        return const Color(0xFFE3F2FD);
      case TestCategory.lowerBodyStrength:
        return const Color(0xFFFCE4EC);
      case TestCategory.upperBodyStrength:
        return const Color(0xFFFFF3E0);
      case TestCategory.speed:
        return const Color(0xFFE8F5E9);
      case TestCategory.agility:
        return const Color(0xFFE0F2F1);
      case TestCategory.coreStrength:
        return const Color(0xFFF3E5F5);
      case TestCategory.endurance:
        return const Color(0xFFE8EAF6);
    }
  }

  Color get _iconColor {
    switch (test.category) {
      case TestCategory.measurement:
        return const Color(0xFF4CAF50);
      case TestCategory.flexibility:
        return const Color(0xFF2196F3);
      case TestCategory.lowerBodyStrength:
        return const Color(0xFFE91E63);
      case TestCategory.upperBodyStrength:
        return const Color(0xFFFF9800);
      case TestCategory.speed:
        return const Color(0xFF4CAF50);
      case TestCategory.agility:
        return const Color(0xFF009688);
      case TestCategory.coreStrength:
        return const Color(0xFF9C27B0);
      case TestCategory.endurance:
        return const Color(0xFF3F51B5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isEnabled ? _iconBackgroundColor : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      test.icon,
                      color: isEnabled ? _iconColor : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          test.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? const Color(0xFF333333) : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          test.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: isEnabled ? const Color(0xFF888888) : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Start Test button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: isEnabled ? onStartTest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEnabled ? const Color(0xFFF28D25) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isEnabled ? 'Start Test' : 'Not Available',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



