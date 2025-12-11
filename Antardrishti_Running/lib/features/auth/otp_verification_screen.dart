import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String requestId;

  const OtpVerificationScreen({
    super.key,
    required this.aadhaarNumber,
    required this.requestId,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _verifying = false;
  String? _error;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        _updateTimer();
      }
    });
  }

  void _updateTimer() {
    if (_resendTimer > 0 && mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _resendTimer--;
          });
          _updateTimer();
        }
      });
    } else if (mounted) {
      setState(() {
        _canResend = true;
      });
    }
  }

  String _formatAadhaar(String aadhaar) {
    if (aadhaar.length == 12) {
      return '${aadhaar.substring(0, 4)} XXXX ${aadhaar.substring(8)}';
    }
    return aadhaar;
  }

  Future<void> _handleVerify() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _error = 'Please enter complete OTP');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final result = await appState.verifyOTP(
        widget.requestId,
        otp,
        widget.aadhaarNumber,
      );

      if (mounted) {
        if (result['requiresRegistration'] == true) {
          // Navigate to registration screen
          Navigator.pushReplacementNamed(
            context,
            '/register',
            arguments: {
              'aadhaarNumber': result['aadhaarNumber'] as String,
              'requestId': result['requestId'] as String,
            },
          );
        } else {
          // User exists, login successful - AppState already updated
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _verifying = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final appState = context.read<AppState>();
      final newRequestId = await appState.sendOTP(widget.aadhaarNumber);

      if (mounted) {
        // Update requestId
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              aadhaarNumber: widget.aadhaarNumber,
              requestId: newRequestId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _onOtpChange(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto verify if all 6 digits entered
    if (index == 5 && value.length == 1) {
      final otp = _otpControllers.map((c) => c.text).join();
      if (otp.length == 6) {
        _handleVerify();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF322259)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  height: 200,
                  child: Image.asset(
                    'assets/images/runner.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 30),

                // Title
                const Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF322259),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'We sent a verification code to your\nAadhaar-linked mobile number\n${_formatAadhaar(widget.aadhaarNumber)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                
                const SizedBox(height: 12),
                
                // Hint for mock OTP
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Demo: Enter 123456',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

                const SizedBox(height: 30),

                // OTP input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF322259),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFF28D25),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOtpChange(index, value),
                      ),
                    );
                  }),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Error message
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_verifying || _loading) ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28D25),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _verifying
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: 24),

                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive code? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    GestureDetector(
                      onTap: _canResend ? _handleResend : null,
                      child: Text(
                        _canResend
                            ? 'Resend OTP'
                            : 'Resend OTP in ${_resendTimer}s',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _canResend
                              ? const Color(0xFFF28D25)
                              : const Color(0xFFAAAAAA),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
