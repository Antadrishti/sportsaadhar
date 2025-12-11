import 'package:flutter/material.dart';

enum TestCategory {
  measurement,
  flexibility,
  lowerBodyStrength,
  upperBodyStrength,
  speed,
  agility,
  coreStrength,
  endurance,
}

class PhysicalTest {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final TestCategory category;
  final int? minAge; // null means no minimum
  final int? maxAge; // null means no maximum

  const PhysicalTest({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    this.minAge,
    this.maxAge,
  });

  /// Check if this test is enabled for a given age
  bool isEnabledForAge(int userAge) {
    if (minAge != null && userAge < minAge!) return false;
    if (maxAge != null && userAge > maxAge!) return false;
    return true;
  }

  /// Get the category display name
  String get categoryName {
    switch (category) {
      case TestCategory.measurement:
        return 'Measurement';
      case TestCategory.flexibility:
        return 'Flexibility';
      case TestCategory.lowerBodyStrength:
        return 'Lower Body Explosive Strength';
      case TestCategory.upperBodyStrength:
        return 'Upper Body Strength';
      case TestCategory.speed:
        return 'Speed';
      case TestCategory.agility:
        return 'Agility';
      case TestCategory.coreStrength:
        return 'Core Strength';
      case TestCategory.endurance:
        return 'Endurance';
    }
  }
}

/// All available physical tests
class PhysicalTests {
  static const List<PhysicalTest> all = [
    PhysicalTest(
      id: 'height',
      name: 'Height',
      description: 'Measure your standing height accurately.',
      icon: Icons.height,
      category: TestCategory.measurement,
    ),
    PhysicalTest(
      id: 'sit_and_reach',
      name: 'Sit and Reach',
      description: 'Measures flexibility of lower back and hamstrings.',
      icon: Icons.accessibility_new,
      category: TestCategory.flexibility,
    ),
    PhysicalTest(
      id: 'standing_vertical_jump',
      name: 'Standing Vertical Jump',
      description: 'Assesses lower body explosive power.',
      icon: Icons.arrow_upward,
      category: TestCategory.lowerBodyStrength,
    ),
    PhysicalTest(
      id: 'standing_broad_jump',
      name: 'Standing Broad Jump',
      description: 'Measures horizontal jumping power.',
      icon: Icons.open_in_full,
      category: TestCategory.lowerBodyStrength,
    ),
    PhysicalTest(
      id: 'medicine_ball_throw',
      name: 'Medicine Ball Throw',
      description: 'Tests upper body throwing strength.',
      icon: Icons.sports_baseball,
      category: TestCategory.upperBodyStrength,
    ),
    PhysicalTest(
      id: '30m_sprint',
      name: '30mts Standing Start',
      description: 'Measures acceleration and sprint speed.',
      icon: Icons.directions_run,
      category: TestCategory.speed,
    ),
    PhysicalTest(
      id: '4x10_shuttle',
      name: '4 X 10 Mts Shuttle Run',
      description: 'Evaluates agility and directional speed.',
      icon: Icons.swap_horiz,
      category: TestCategory.agility,
    ),
    PhysicalTest(
      id: 'sit_ups',
      name: 'Sit Ups',
      description: 'Measures core muscular endurance.',
      icon: Icons.fitness_center,
      category: TestCategory.coreStrength,
    ),
    PhysicalTest(
      id: 'push_ups',
      name: 'Push Ups',
      description: 'Tests upper body strength and endurance.',
      icon: Icons.sports_gymnastics,
      category: TestCategory.upperBodyStrength,
    ),
    PhysicalTest(
      id: '800m_run',
      name: '800m Run',
      description: 'Endurance test for athletes under 12 years.',
      icon: Icons.timer,
      category: TestCategory.endurance,
      maxAge: 11, // Only for under 12
    ),
    PhysicalTest(
      id: '1600m_run',
      name: '1.6km Run',
      description: 'Endurance test for athletes 12 years and above.',
      icon: Icons.timer,
      category: TestCategory.endurance,
      minAge: 12, // Only for 12+
    ),
  ];
}



