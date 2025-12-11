import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/models/physical_test.dart';
import '../../main.dart';
import 'widgets/test_card.dart';

class PhysicalAssessmentScreen extends StatefulWidget {
  const PhysicalAssessmentScreen({super.key});

  @override
  State<PhysicalAssessmentScreen> createState() => _PhysicalAssessmentScreenState();
}

class _PhysicalAssessmentScreenState extends State<PhysicalAssessmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PhysicalTest> _getFilteredTests() {
    if (_searchQuery.isEmpty) {
      return PhysicalTests.all;
    }
    return PhysicalTests.all.where((test) {
      return test.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          test.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          test.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _handleTestStart(PhysicalTest test) {
    // Check if this is a height test
    if (test.id == 'height') {
      // Show measurement method selection dialog
      _showHeightMeasurementOptions(test);
    }
    // Check if this is a vertical jump test
    else if (test.id == 'standing_vertical_jump') {
      // Navigate directly to vertical jump recording screen
      Navigator.pushNamed(
        context,
        '/vertical-jump-recording',
        arguments: {
          'test': test,
        },
      );
    }
    // Check if this is a sit-ups test
    else if (test.id == 'sit_ups') {
      // Navigate directly to sit-ups recording screen
      Navigator.pushNamed(
        context,
        '/situps-recording',
        arguments: {
          'test': test,
        },
      );
    }
    // Check if this is a sit and reach test
    else if (test.id == 'sit_and_reach') {
      // Navigate directly to sit and reach recording screen
      Navigator.pushNamed(
        context,
        '/sit-and-reach-recording',
        arguments: {
          'test': test,
        },
      );
    }
    // Check if this is a shuttle run test
    else if (test.id == '4x10_shuttle') {
      // Navigate directly to shuttle run setup screen (face verification removed)
      Navigator.pushNamed(
        context,
        '/shuttle-run-setup',
        arguments: {
          'test': test,
        },
      );
    }
    // Check if this is a broad jump test
    else if (test.id == 'standing_broad_jump') {
      final userHeight = context.read<AppState>().user?.height;
      if (userHeight == null) {
        _showErrorDialog('Profile height not found. Please update your profile.');
        return;
      }
      // Navigate directly to broad jump recording screen
      Navigator.pushNamed(
        context,
        '/broad-jump-recording',
        arguments: {
          'test': test,
          'userHeightCm': userHeight,
        },
      );
    }
    // Check if this is a running test
    else if (test.id == '800m_run' || test.id == '1600m_run' || test.id == '30m_sprint') {
      // Determine target distance
      double targetDistance;
      switch (test.id) {
        case '800m_run':
          targetDistance = 800.0;
          break;
        case '1600m_run':
          targetDistance = 1600.0;
          break;
        case '30m_sprint':
          targetDistance = 30.0;
          break;
        default:
          targetDistance = 0.0;
      }

      // Navigate directly to test run tracking screen (face verification removed)
      Navigator.pushNamed(
        context,
        '/test-run-tracking',
        arguments: {
          'test': test,
          'targetDistance': targetDistance,
        },
      );
    } else {
      // Show placeholder for other tests
      _showTestPlaceholder(test);
    }
  }

  void _showTestPlaceholder(PhysicalTest test) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(test.icon, color: const Color(0xFFF28D25)),
            const SizedBox(width: 8),
            Expanded(child: Text(test.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(test.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFF28D25), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Test functionality will be integrated soon.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFF28D25))),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFF28D25))),
          ),
        ],
      ),
    );
  }

  void _showHeightMeasurementOptions(PhysicalTest test) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'Choose Measurement Method',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF322259),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select how you want to measure your height',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // AR Measurement Option (Recommended)
            _buildMeasurementOption(
              icon: Icons.view_in_ar,
              title: 'AR Height Measurement',
              subtitle: 'Stand naturally - no special pose required',
              badge: 'RECOMMENDED',
              badgeColor: const Color(0xFF00C853),
              features: [
                '✓ Just stand still naturally',
                '✓ ±2cm accuracy with depth sensing',
                '✓ Real-time visual feedback',
                '✓ Automatic measurement',
              ],
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.pushNamed(
                  context,
                  '/ar-height-measurement',
                  arguments: {'test': test},
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Legacy Measurement Option
            _buildMeasurementOption(
              icon: Icons.accessibility_new,
              title: 'Reference Pose Method',
              subtitle: 'Touch your foot with your hand',
              badge: 'LEGACY',
              badgeColor: Colors.grey,
              features: [
                '• Requires specific pose',
                '• Finger touching foot as reference',
                '• Works on all devices',
              ],
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                Navigator.pushNamed(
                  context,
                  '/height-measurement',
                  arguments: {'test': test},
                );
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: badgeColor.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: badgeColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF322259),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(left: 60, bottom: 4),
                child: Text(
                  feature,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userAge = appState.user?.age ?? 18; // Default to 18 if not available
    final filteredTests = _getFilteredTests();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Physical Assessment',
          style: TextStyle(
            color: Color(0xFF322259),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF322259)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('About Tests'),
                  content: const Text(
                    'Complete these physical tests to assess your athletic abilities. '
                    'Your results will be used to generate your Sports Aadhaar score and card.\n\n'
                    'Note: Some tests are age-specific. Tests that don\'t apply to your age group will appear grayed out.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it', style: TextStyle(color: Color(0xFFF28D25))),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search for a test',
                hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF888888)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF888888)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF28D25), width: 1),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Test list
          Expanded(
            child: filteredTests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No tests found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTests.length,
                    itemBuilder: (context, index) {
                      final test = filteredTests[index];
                      final isEnabled = test.isEnabledForAge(userAge);

                      return TestCard(
                        test: test,
                        isEnabled: isEnabled,
                        onStartTest: isEnabled ? () => _handleTestStart(test) : null,
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                            duration: 300.ms,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

