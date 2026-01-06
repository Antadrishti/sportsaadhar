import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/video_recorder_screen.dart';
import 'screens/vertical_jump_screen.dart';


import 'screens/run_tracking_screen.dart';
import 'screens/sit_ups_screen.dart';
import 'screens/broad_jump_screen.dart';
import 'screens/sit_and_reach_recording_screen.dart';
import 'screens/sit_and_reach_result_screen.dart';
import 'screens/shuttle_run_setup_screen.dart';
import 'screens/shuttle_run_tracking_screen.dart';
import 'screens/shuttle_run_result_screen.dart';
import 'models/test_result_model.dart'; // Needed for casting arguments
import 'models/physical_test.dart'; // Needed for casting arguments
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
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/video_recorder': (context) => const VideoRecorderScreen(),
        '/vertical_jump': (context) => const VerticalJumpScreen(),

        // Unified Run Tracking (Endurance & Sprints)
        '/run_tracking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return RunTrackingScreen(
             test: args['test'],
             targetDistance: args['targetDistance'],
          );
        },
        
        // Migrated Routes
        '/sit_ups': (context) => const SitUpsScreen(),
        '/standing_broad_jump': (context) => const BroadJumpScreen(),
        
        '/sit_and_reach': (context) => const SitAndReachRecordingScreen(),
        '/sit_and_reach_result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as TestResultModel;
          return SitAndReachResultScreen(testResult: args);
        },
        
        '/shuttle_run_setup': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as PhysicalTest;
          return ShuttleRunSetupScreen(test: args);
        },
        '/shuttle-run-tracking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ShuttleRunTrackingScreen(
            test: args['test'],
            startPosition: args['startPosition'],
          );
        },
        '/shuttle-run-result': (context) {
           final args = ModalRoute.of(context)!.settings.arguments as Map;
           return ShuttleRunResultScreen(
             test: args['test'],
             result: args['result'],
           );
        },
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
