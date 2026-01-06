import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/physical_test.dart';
import '../services/gemini_service.dart';
import '../services/api_service.dart';
import 'video_recorder_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  double _maxHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMaxHeight();
  }

  Future<void> _loadMaxHeight() async {
    // Try API first
    final apiHeight = await ApiService.getLatestTestValue('Height Measurement');
    if (apiHeight != null && apiHeight > 0) {
      setState(() => _maxHeight = apiHeight);
      return;
    }
    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxHeight = prefs.getDouble('max_height') ?? 0.0;
    });
  }

  Future<void> _saveHeight(double newHeight) async {
    final prefs = await SharedPreferences.getInstance();
    if (newHeight > _maxHeight) {
      await prefs.setDouble('max_height', newHeight);
      setState(() {
        _maxHeight = newHeight;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New record height saved!')),
        );
      }
    }
  }

  Future<void> _handleUpload(ImageSource source, {required bool isVideo}) async {
    final picker = ImagePicker();
    final XFile? media;
    if (isVideo) {
      media = await picker.pickVideo(source: source);
    } else {
      media = await picker.pickImage(source: source);
    }

    if (media != null) {
      setState(() => _isLoading = true);
      _showLoadingDialog();

      try {
        final result = await GeminiService().analyzeHeight(File(media.path), isVideo: isVideo);
        if (mounted) {
           Navigator.pop(context); // Close loading
        }

        // Parse logic
        if (result.startsWith('Height:')) {
           final heightStr = result.replaceAll('Height:', '').replaceAll('cm', '').trim();
           final height = double.tryParse(heightStr);
           if (height != null) {
             await _saveHeight(height);
           }
           if (mounted) _showResultDialog(result);
        } else if (result.startsWith('ERROR:')) {
           if (mounted) _showErrorDialog(result.replaceAll('ERROR:', '').trim());
        } else {
           if (mounted) _showResultDialog(result); // Fallback
        }

      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showErrorDialog(String message) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation Failed ⚠️'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Result'),
        content: SingleChildScrollView(child: Text(result, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/video_recorder', arguments: {'mode': 'video'})
                    .then((value) => _loadMaxHeight()); // Refresh after return
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/video_recorder', arguments: {'mode': 'photo'})
                    .then((value) => _loadMaxHeight());
              },
            ),
             ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Video'),
              onTap: () {
                Navigator.pop(context);
                _handleUpload(ImageSource.gallery, isVideo: true);
              },
            ),
             ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Upload Photo'),
              onTap: () {
                Navigator.pop(context);
                _handleUpload(ImageSource.gallery, isVideo: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow gradient to go behind AppBar
      appBar: AppBar(
        title: const Text('SAI Sports Aadhar'),
        backgroundColor: Colors.transparent, // Transparent AppBar
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
         decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF0F2F5)],
          ),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Height display banner
            if (_maxHeight > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latest Height Record',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_maxHeight.toStringAsFixed(1)} cm',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            
            Text(
              'Available Tests',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            
            // Test cards grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                // Height Analysis
                _buildTestCard(
                  icon: Icons.height,
                  title: 'Height',
                  subtitle: 'AI Analysis',
                  color: Colors.blue.shade600,
                  isEnabled: true,
                  onTap: () => _showOptions(context),
                  delay: 0,
                ),
                
                // Vertical Jump
                _buildTestCard(
                  icon: Icons.sports_gymnastics,
                  title: 'Vertical Jump',
                  subtitle: _maxHeight > 0 ? 'Ready' : 'Need height',
                  color: Colors.orange.shade600,
                  isEnabled: _maxHeight > 0,
                  onTap: () => Navigator.pushNamed(context, '/vertical_jump'),
                  delay: 100,
                ),

                // Sit Ups
                _buildTestCard(
                  icon: Icons.fitness_center,
                  title: 'Sit-Ups',
                  subtitle: 'Core Strength',
                  color: Colors.deepOrange.shade600,
                  isEnabled: true,
                  onTap: () => Navigator.pushNamed(context, '/sit_ups'),
                  delay: 200,
                ),

                // Broad Jump
                _buildTestCard(
                  icon: Icons.directions_walk, 
                  title: 'Broad Jump',
                  subtitle: 'Leg Power',
                  color: Colors.purple.shade600,
                  isEnabled: true,
                  onTap: () => Navigator.pushNamed(context, '/standing_broad_jump'),
                  delay: 300,
                ),

                // Sit and Reach
                _buildTestCard(
                  icon: Icons.accessibility_new,
                  title: 'Sit & Reach',
                  subtitle: 'Flexibility',
                  color: Colors.blueAccent.shade700,
                  isEnabled: true,
                  onTap: () => Navigator.pushNamed(
                    context, 
                    '/sit_and_reach',
                    arguments: PhysicalTest(id: 'flex1', name: 'Sit and Reach', description: 'Flexibility', icon: Icons.accessibility_new, category: TestCategory.flexibility)
                  ), 
                  delay: 400,
                ),
                
                 // Shuttle Run
                _buildTestCard(
                  icon: Icons.sync_alt,
                  title: '4x10m Shuttle',
                  subtitle: 'Agility',
                  color: Colors.indigo.shade600,
                  isEnabled: true,
                  onTap: () => Navigator.pushNamed(
                    context, 
                    '/shuttle_run_setup',
                    arguments: PhysicalTest(id: 'agil1', name: '4x10m Shuttle Run', description: 'Agility Test', icon: Icons.sync_alt, category: TestCategory.agility)
                  ),
                  delay: 500,
                ),
                
                // Endurance Run
                _buildTestCard(
                  icon: Icons.timer,
                  title: 'Endurance Run',
                  subtitle: '600m Run/Walk',
                  color: Colors.green.shade600,
                  isEnabled: true,
                  onTap: () => Navigator.pushNamed(
                    context, 
                    '/run_tracking',
                    arguments: {
                      'test': const PhysicalTest(id: 'end1', name: 'Endurance Run (600m)', description: 'Endurance', icon: Icons.timer, category: TestCategory.endurance),
                      'targetDistance': 600.0,
                    }
                  ),
                  delay: 600,
                ),
                
                // 30m Sprint
                _buildTestCard(
                  icon: Icons.directions_run,
                  title: '30m Sprint',
                  subtitle: 'Speed Test',
                  color: Colors.teal.shade600,
                  isEnabled: true,
                  onTap: () => Navigator.pushNamed(
                    context, 
                    '/run_tracking',
                    arguments: {
                      'test': const PhysicalTest(id: 'spd1', name: '30m Sprint', description: 'Speed Test', icon: Icons.directions_run, category: TestCategory.speed),
                      'targetDistance': 30.0,
                    }
                  ),
                  delay: 700,
                ),

                // Medicine Ball Throw - Coming Soon
                _buildTestCard(
                  icon: Icons.sports_baseball,
                  title: 'Med Ball Throw',
                  subtitle: 'Coming Soon',
                  color: Colors.red.shade600,
                  isEnabled: false,
                  isComingSoon: true,
                  onTap: () {},
                  delay: 800,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildTestCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isEnabled,
    bool isComingSoon = false,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled ? color.withOpacity(0.1) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isEnabled ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isEnabled ? null : Colors.grey,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              isComingSoon
                  ? Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SOON',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    )
                  : Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 12,
                            color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ],
          ),
        ),
      ),
    ).animate().fade(delay: delay.ms).slideY(begin: 0.2, end: 0, delay: delay.ms, curve: Curves.easeOutQuart);
  }
}
