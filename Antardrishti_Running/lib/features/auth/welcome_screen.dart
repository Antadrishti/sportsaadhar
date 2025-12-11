import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Logo at the center
              Image.asset(
                'assets/images/logo.jpg',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              const SizedBox(height: 40),
              
              // App name
              const Text(
                'SportsAadhaar',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF322259),
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 20),
              
              // Tagline
              const Text(
                'Unleash Your Potential. Your Journey to Sporting Excellence Starts Here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              
              const Spacer(),
              
              // Single button for Aadhaar verification
              Column(
                children: [
                  // Continue with Aadhaar button (Orange)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup-aadhaar');
                      },
                      icon: const Icon(Icons.verified_user, size: 22),
                      label: const Text(
                        'Continue with Aadhaar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF28D25),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                  
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
                        Icon(Icons.info_outline, color: Color(0xFF666666), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verify your identity using your 12-digit Aadhaar number to get started.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
