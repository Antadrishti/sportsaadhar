import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/video_recorder_screen.dart';
import 'screens/vertical_jump_screen.dart';

import 'screens/medicine_ball_throw_screen.dart';
import 'screens/sprint_30m_screen.dart';
import 'screens/shuttle_run_screen.dart';

import 'screens/endurance_run_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAI Sports Aadhar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/video_recorder': (context) => const VideoRecorderScreen(),
        '/vertical_jump': (context) => const VerticalJumpScreen(),

        '/medicine_ball_throw': (context) => const MedicineBallThrowScreen(),
        '/sprint_30m': (context) => const Sprint30mScreen(),
        '/shuttle_run': (context) => const ShuttleRunScreen(),

        '/endurance_run': (context) => const EnduranceRunScreen(),
      },
    );
  }
}

// Wrapper to check auth state on startup
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await ApiService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
