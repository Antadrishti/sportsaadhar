import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_empty, color: Color(0xFFF28D25)),
            SizedBox(width: 8),
            Text('Coming Soon'),
          ],
        ),
        content: const Text('This feature is under development and will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFF28D25))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Image.asset(
                  'assets/images/logo.jpg',
                  width: 120,
                  height: 120,
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 24),

                // Welcome text
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                const Text(
                  'SportsAadhaar',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF322259),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 8),

                const Text(
                  'Your journey to becoming a sports star\nstarts here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 40),

                // Feature Cards
                _FeatureCard(
                  icon: Icons.assignment_outlined,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Record Your Tests',
                  subtitle: 'Easily log your physical test results.',
                  onTap: () => Navigator.pushNamed(context, '/physical-assessment'),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                    ),

                const SizedBox(height: 12),

                _FeatureCard(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFFF28D25),
                  title: 'Get Your Score',
                  subtitle: 'Receive an instant performance score.',
                  onTap: () => _showComingSoon(context),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                    ),

                const SizedBox(height: 12),

                _FeatureCard(
                  icon: Icons.card_membership_outlined,
                  iconColor: const Color(0xFF2196F3),
                  title: 'Generate Your Card',
                  subtitle: 'Create your official Sports Aadhaar Card.',
                  onTap: () => _showComingSoon(context),
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideX(
                      begin: -0.1,
                      end: 0,
                    ),

                const SizedBox(height: 32),

                // My Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28D25),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFCCCCCC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
