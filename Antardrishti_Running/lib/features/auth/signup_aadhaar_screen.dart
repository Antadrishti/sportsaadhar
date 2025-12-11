import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../main.dart';
import 'otp_verification_screen.dart';

class SignupAadhaarScreen extends StatefulWidget {
  const SignupAadhaarScreen({super.key});

  @override
  State<SignupAadhaarScreen> createState() => _SignupAadhaarScreenState();
}

class _SignupAadhaarScreenState extends State<SignupAadhaarScreen> {
  final _aadhaarController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Runner illustration
                SizedBox(
                  height: 280,
                  child: Image.asset(
                    'assets/images/runner.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                ),
                
                const SizedBox(height: 30),
                
                // Title
                const Text(
                  'Aadhaar Verification',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF322259),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Enter your 12-digit Aadhaar number to get started.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                
                const SizedBox(height: 32),
                
                // Aadhaar number field
                TextField(
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter 12-digit Aadhaar number',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                        ),
                      ),
                      child: const Center(
                        widthFactor: 1,
                        child: Icon(
                          Icons.credit_card,
                          color: Color(0xFF333333),
                          size: 24,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 48),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFF28D25), width: 1.5),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, letterSpacing: 2),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                
                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Send OTP button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleSendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28D25),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Verify Aadhaar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                
                const SizedBox(height: 16),
                
                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF666666), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'An OTP will be sent to your Aadhaar-linked mobile number for verification.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                
                const SizedBox(height: 24),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendOTP() async {
    final aadhaar = _aadhaarController.text.trim();

    if (aadhaar.isEmpty || aadhaar.length != 12) {
      setState(() => _error = 'Please enter a valid 12-digit Aadhaar number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Send OTP for Aadhaar verification
      final appState = context.read<AppState>();
      final requestId = await appState.sendOTP(aadhaar);

      if (mounted) {
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              aadhaarNumber: aadhaar,
              requestId: requestId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}



