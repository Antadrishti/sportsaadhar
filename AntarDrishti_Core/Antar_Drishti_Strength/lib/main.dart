import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/sit_ups_screen.dart';
import 'screens/broad_jump_screen.dart';
import 'screens/medicine_ball_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tests',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tests'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select a Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // Sit-Ups Card
            _TestCard(
              title: 'Sit-Ups',
              subtitle: 'Count reps in 60 seconds',
              icon: Icons.accessibility_new,
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SitUpsScreen()),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Broad Jump Card
            _TestCard(
              title: 'Broad Jump',
              subtitle: 'Measure horizontal jump distance',
              icon: Icons.directions_run,
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BroadJumpScreen()),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Medicine Ball Card
            _TestCard(
              title: 'Medicine Ball',
              subtitle: 'Overhead backward throw distance',
              icon: Icons.sports_baseball,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicineBallScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
