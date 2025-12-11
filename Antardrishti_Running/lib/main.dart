import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/models/user.dart';
import 'core/models/user_progress.dart';
import 'core/services/auth_service.dart';
import 'core/services/local_db_service.dart';
import 'core/services/pose_detection_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/api_service.dart';
import 'core/services/progress_service.dart';
import 'features/app_shell.dart';
import 'features/home/home_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/auth/signup_aadhaar_screen.dart';
import 'features/tests/test_list_screen.dart';
import 'features/tests/record_test_screen.dart';
import 'features/tests/video_upload_screen.dart';
import 'features/tests/physical_assessment_screen.dart';
import 'features/tests/test_face_verification_screen.dart';
import 'features/tests/test_run_tracking_screen.dart';
import 'features/tests/test_results_screen.dart';
import 'features/tests/height_face_verification_screen.dart';
import 'features/tests/height_measurement_screen.dart';
import 'features/tests/height_result_screen.dart';
import 'features/tests/ar_height_measurement_screen.dart';
import 'features/tests/vertical_jump_face_verification_screen.dart';
import 'features/tests/vertical_jump_recording_screen.dart';
import 'features/tests/vertical_jump_result_screen.dart';
import 'features/tests/situps_face_verification_screen.dart';
import 'features/tests/situps_recording_screen.dart';
import 'features/tests/situps_result_screen.dart';
import 'features/tests/sit_and_reach_face_verification_screen.dart';
import 'features/tests/sit_and_reach_recording_screen.dart';
import 'features/tests/sit_and_reach_result_screen.dart';
import 'features/tests/shuttle_run_face_verification_screen.dart';
import 'features/tests/shuttle_run_setup_screen.dart';
import 'features/tests/shuttle_run_tracking_screen.dart';
import 'features/tests/shuttle_run_result_screen.dart';
import 'features/tests/broad_jump_face_verification_screen.dart';
import 'features/tests/broad_jump_recording_screen.dart';
import 'features/tests/broad_jump_result_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'core/services/shuttle_run_service.dart';
import 'core/models/physical_test.dart';
import 'core/models/test_result_model.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/psychometric/psychometric_intro_screen.dart';
import 'features/card/sports_card_screen.dart';
import 'features/demo-testing/demo_testing.dart';
import 'features/run/run_tracking_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/splash_screen.dart';

class AppState extends ChangeNotifier {
  User? user;
  UserProgress? progress;
  bool initialized = false;

  final AuthService _authService;
  final SyncService _syncService;
  final ProgressService _progressService;

  AppState(this._authService, this._syncService, this._progressService);

  Future<void> init() async {
    user = await _authService.getCurrentUser();
    initialized = true;

    if (user != null) {
      await _syncService.syncPendingResults(user!);
      // Sync progress and update streak on app start
      await syncProgressOnLogin();
    }
    notifyListeners();
  }

  /// Sync progress data from backend
  Future<void> syncProgressOnLogin() async {
    if (user == null) return;

    try {
      // Update streak on daily login
      await _progressService.updateStreak(user!.id);
      
      // Sync progress data
      progress = await _progressService.syncProgress(user!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing progress: $e');
      // Don't throw - allow app to continue even if progress sync fails
    }
  }

  /// Manually refresh progress data
  Future<void> refreshProgress() async {
    if (user == null) return;

    try {
      progress = await _progressService.getProgress(user!.id, forceSync: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing progress: $e');
      rethrow;
    }
  }

  // Send OTP for Aadhaar verification
  Future<String> sendOTP(String aadhaarNumber) async {
    return await _authService.sendOTP(aadhaarNumber);
  }

  // Verify OTP and login or redirect to registration
  Future<Map<String, dynamic>> verifyOTP(
      String requestId, String code, String aadhaarNumber) async {
    final result = await _authService.verifyOTP(requestId, code, aadhaarNumber);

    if (!result['requiresRegistration']) {
      final loggedInUser = result['user'] as User;
      user = loggedInUser;
      await _syncService.syncPendingResults(loggedInUser);
      
      // Sync progress on successful login
      await syncProgressOnLogin();
      
      notifyListeners();
    }

    return result;
  }

  // Complete registration after Aadhaar OTP verification
  Future<void> completeRegistration({
    required String name,
    required String aadhaarNumber,
    required String requestId,
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String disability,
    required String phoneNumber,
    String? email,
    File? profileImage,
  }) async {
    final registered = await _authService.completeRegistration(
      name: name,
      aadhaarNumber: aadhaarNumber,
      requestId: requestId,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      address: address,
      city: city,
      state: state,
      pincode: pincode,
      disability: disability,
      phoneNumber: phoneNumber,
      email: email,
      profileImage: profileImage,
    );
    user = registered;
    await _syncService.syncPendingResults(registered);
    
    // Sync progress on successful registration
    await syncProgressOnLogin();
    
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    progress = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final updated = await _authService.fetchProfileAndUpdate();
    user = updated;
    
    // Also refresh progress when refreshing profile
    if (user != null) {
      await refreshProgress();
    }
    
    notifyListeners();
  }
}

void main() {
  final authService = AuthService();
  final apiService = ApiService();
  final localDb = LocalDbService();
  final syncService = SyncService(localDb);
  final poseDetectionService = PoseDetectionService();
  final progressService = ProgressService(apiService);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AppState(authService, syncService, progressService)..init(),
      ),
      Provider.value(value: localDb),
      Provider.value(value: syncService),
      Provider.value(value: poseDetectionService),
      Provider.value(value: apiService),
      Provider.value(value: progressService),
    ],
    child: const SAIApp(),
  ));
}

class SAIApp extends StatelessWidget {
  const SAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SAI Talent Platform',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          // If a web URL provides an initial route (e.g., /register),
          // routes below will resolve it even before initialization completes.
          home: !state.initialized
              ? const SplashScreen()
              : state.user == null
                  ? const WelcomeScreen()
                  : const AppShell(),
          routes: {
            '/welcome': (_) => const WelcomeScreen(),
            '/signup-aadhaar': (_) => const SignupAadhaarScreen(),
            '/register': (_) => const RegisterScreen(),
            '/otp-verify': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return OtpVerificationScreen(
                  aadhaarNumber: args['aadhaarNumber'] as String,
                  requestId: args['requestId'] as String,
                );
              }
              return const WelcomeScreen();
            },
            '/home': (_) => const AppShell(),
            '/home-old': (_) => const HomeScreen(),
            '/physical-assessment': (_) => const PhysicalAssessmentScreen(),
            '/test-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return TestFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                  targetDistance: args['targetDistance'] as double,
                );
              }
              return const HomeScreen();
            },
            '/test-run-tracking': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return TestRunTrackingScreen(
                  test: args['test'] as PhysicalTest,
                  targetDistance: args['targetDistance'] as double,
                );
              }
              return const HomeScreen();
            },
            '/test-results': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args != null && args is TestResultModel) {
                return TestResultsScreen(testResult: args);
              }
              return const HomeScreen();
            },
            '/height-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return HeightFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                  videoPath: args['videoPath'] as String?,
                );
              }
              return const HomeScreen();
            },
            '/height-measurement': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return HeightMeasurementScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/ar-height-measurement': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return ARHeightMeasurementScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/height-result': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              debugPrint('📊 Height result route called. Args type: ${args.runtimeType}');
              
              // Handle AR measurement result (Map with heightCm)
              if (args != null && args is Map<String, dynamic>) {
                final test = args['test'] as PhysicalTest?;
                final heightCm = args['heightCm'] as double?;
                final isARMeasurement = args['isARMeasurement'] as bool? ?? false;
                
                if (test != null && heightCm != null && isARMeasurement) {
                  // Create TestResultModel from AR measurement
                  final testResult = TestResultModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    testType: 'height',
                    testName: test.name,
                    distance: 0, // Not applicable for height test
                    timeTaken: 0, // Not applicable for height test
                    speed: 0, // Not applicable for height test
                    date: DateTime.now(),
                    isHeightVerified: true,
                    measuredHeight: heightCm,
                    registeredHeight: heightCm, // Will be updated from user profile
                  );
                  return HeightResultScreen(testResult: testResult);
                }
              }
              
              // Handle standard TestResultModel
              if (args != null && args is TestResultModel) {
                debugPrint('✅ Valid TestResultModel received. isHeightVerified: ${args.isHeightVerified}, measuredHeight: ${args.measuredHeight}');
                return HeightResultScreen(testResult: args);
              } else {
                debugPrint('❌ Invalid arguments for height result screen. Args: $args');
              }
              return const HomeScreen();
            },
            '/vertical-jump-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return VerticalJumpFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                  videoPath: args['videoPath'] as String?,
                );
              }
              return const HomeScreen();
            },
            '/vertical-jump-recording': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return VerticalJumpRecordingScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/vertical-jump-result': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args != null && args is TestResultModel) {
                return VerticalJumpResultScreen(testResult: args);
              }
              return const HomeScreen();
            },
            '/situps-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return SitupsFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                  videoPath: args['videoPath'] as String?,
                );
              }
              return const HomeScreen();
            },
            '/situps-recording': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return SitupsRecordingScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/situps-result': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args != null && args is TestResultModel) {
                return SitupsResultScreen(testResult: args);
              }
              return const HomeScreen();
            },
            '/sit-and-reach-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return SitAndReachFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                  videoPath: args['videoPath'] as String?,
                );
              }
              return const HomeScreen();
            },
            '/sit-and-reach-recording': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return SitAndReachRecordingScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/sit-and-reach-result': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args != null && args is TestResultModel) {
                return SitAndReachResultScreen(testResult: args);
              }
              return const HomeScreen();
            },
            '/shuttle-run-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return ShuttleRunFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/shuttle-run-setup': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return ShuttleRunSetupScreen(
                  test: args['test'] as PhysicalTest,
                );
              }
              return const HomeScreen();
            },
            '/shuttle-run-tracking': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return ShuttleRunTrackingScreen(
                  test: args['test'] as PhysicalTest,
                  startPosition: args['startPosition'] as Position,
                );
              }
              return const HomeScreen();
            },
            '/shuttle-run-result': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return ShuttleRunResultScreen(
                  test: args['test'] as PhysicalTest,
                  result: args['result'] as ShuttleRunResult,
                );
              }
              return const HomeScreen();
            },
            '/broad-jump-face-verification': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return BroadJumpFaceVerificationScreen(
                  test: args['test'] as PhysicalTest,
                  userHeightCm: args['userHeightCm'] as double,
                  videoPath: args['videoPath'] as String?,
                );
              }
              return const HomeScreen();
            },
            '/broad-jump-recording': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return BroadJumpRecordingScreen(
                  test: args['test'] as PhysicalTest,
                  userHeightCm: args['userHeightCm'] as double,
                );
              }
              return const HomeScreen();
            },
            '/broad-jump-result': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              if (args != null) {
                return BroadJumpResultScreen(
                  testResult: args['testResult'] as TestResultModel,
                  userHeightCm: args['userHeightCm'] as double,
                  rating: args['rating'] as String?,
                );
              }
              return const HomeScreen();
            },
            '/tests': (_) => const TestListScreen(),
            '/record-test': (_) => const RecordTestScreen(),
            '/upload-video': (_) => const VideoUploadScreen(),
            '/leaderboard': (_) => const LeaderboardScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/progress': (_) => const ProgressScreen(),
            '/psychometric': (_) => const PsychometricIntroScreen(),
            '/sports-card': (_) => const SportsCardScreen(),
            '/testing': (_) => const DemoTesting(),
            '/run': (_) => const RunTrackingScreen(),
          },
        );
      },
    );
  }
}
