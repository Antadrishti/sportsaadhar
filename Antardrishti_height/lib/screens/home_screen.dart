import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      appBar: AppBar(
        title: const Text('SAI Sports Aadhar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Height display banner
            if (_maxHeight > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Recorded Height: ${_maxHeight.toStringAsFixed(1)} cm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold, 
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            
            const Text(
              'Available Tests',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Test cards grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                // Height Analysis
                _buildTestCard(
                  icon: Icons.height,
                  title: 'Height',
                  subtitle: 'Measure height',
                  color: Colors.blue,
                  isEnabled: true,
                  onTap: () => _showOptions(context),
                ),
                
                // Vertical Jump
                _buildTestCard(
                  icon: Icons.sports_gymnastics,
                  title: 'Vertical Jump',
                  subtitle: _maxHeight > 0 ? 'Ready' : 'Need height',
                  color: Colors.orange,
                  isEnabled: _maxHeight > 0,
                  onTap: () => Navigator.pushNamed(context, '/vertical_jump'),
                ),
                

                
                // Medicine Ball Throw - Coming Soon
                _buildTestCard(
                  icon: Icons.sports_baseball,
                  title: 'Med Ball Throw',
                  subtitle: 'Coming Soon',
                  color: Colors.red,
                  isEnabled: false,
                  isComingSoon: true,
                  onTap: () {},
                ),
                
                // 30m Sprint - Coming Soon
                _buildTestCard(
                  icon: Icons.directions_run,
                  title: '30m Sprint',
                  subtitle: 'Coming Soon',
                  color: Colors.teal,
                  isEnabled: false,
                  isComingSoon: true,
                  onTap: () {},
                ),
                
                // 4x10m Shuttle Run - Coming Soon
                _buildTestCard(
                  icon: Icons.sync_alt,
                  title: '4x10m Shuttle',
                  subtitle: 'Coming Soon',
                  color: Colors.indigo,
                  isEnabled: false,
                  isComingSoon: true,
                  onTap: () {},
                ),
                

                
                // Endurance Run - Coming Soon
                _buildTestCard(
                  icon: Icons.timer,
                  title: 'Endurance Run',
                  subtitle: '800m/1.6km',
                  color: Colors.green,
                  isEnabled: false,
                  isComingSoon: true,
                  onTap: () {},
                ),
              ],
            ),
          ],
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
  }) {
    return Card(
      elevation: isEnabled ? 4 : 2,
      color: isEnabled ? Colors.white : Colors.grey.shade100,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon, 
                    size: 40, 
                    color: isEnabled ? color : Colors.grey,
                  ),
                  if (isComingSoon)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOON',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.black87 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isEnabled ? Colors.black54 : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
