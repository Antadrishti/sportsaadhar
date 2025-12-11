import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import 'camera_screen.dart';

/// Home screen where user enters their height
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _heightController = TextEditingController();
  double _heightCm = AppConstants.defaultHeightCm;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _heightController.text = _heightCm.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  void _onHeightChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      setState(() {
        _heightCm = parsed.clamp(AppConstants.minHeightCm, AppConstants.maxHeightCm);
        _errorMessage = null;
      });
    }
  }

  void _onSliderChanged(double value) {
    setState(() {
      _heightCm = value;
      _heightController.text = value.toStringAsFixed(0);
      _errorMessage = null;
    });
  }

  bool _validateHeight() {
    final parsed = double.tryParse(_heightController.text);
    if (parsed == null) {
      setState(() => _errorMessage = 'Please enter a valid number');
      return false;
    }
    if (parsed < AppConstants.minHeightCm || parsed > AppConstants.maxHeightCm) {
      setState(() => _errorMessage = 'Height must be between ${AppConstants.minHeightCm.toInt()} and ${AppConstants.maxHeightCm.toInt()} cm');
      return false;
    }
    return true;
  }

  void _startRecording() {
    if (!_validateHeight()) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(heightCm: _heightCm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App title
                const Text(
                  '🏀 Jump Height',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Measure your vertical jump',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                
                // Height input card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Enter Your Height',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Height display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                              ],
                              onChanged: _onHeightChanged,
                            ),
                          ),
                          Text(
                            'cm',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Height slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF00D9FF),
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: const Color(0xFF00D9FF),
                          overlayColor: const Color(0xFF00D9FF).withOpacity(0.2),
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: _heightCm.clamp(100, 250),
                          min: 100,
                          max: 250,
                          divisions: 150,
                          onChanged: _onSliderChanged,
                        ),
                      ),
                      
                      // Height in feet/inches
                      Text(
                        _convertToFeetInches(_heightCm),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      
                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to use:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInstruction('1', 'Enter your height above'),
                      _buildInstruction('2', 'Position your phone to capture full body'),
                      _buildInstruction('3', 'Stand still, then jump!'),
                      _buildInstruction('4', 'View your jump height result'),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Start button
                ElevatedButton(
                  onPressed: _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF00D9FF).withOpacity(0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Start Recording',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _convertToFeetInches(double cm) {
    final totalInches = cm / 2.54;
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    return "$feet' $inches\"";
  }
}
