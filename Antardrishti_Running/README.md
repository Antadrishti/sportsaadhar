# Sports Aadhaar (SAI Talent Platform)

Sports Aadhaar is a Flutter app that helps SAI coaches and athletes capture performance videos, run on-device pose analysis, cache the results offline, and sync them to the Sports Aadhaar API when the network is available. The UI recently received a Material 3 refresh with a splash screen, gradient auth flows, and reusable widgets so new contributors can focus on features instead of scaffolding.

## Table of Contents
- [Overview](#overview)
- [Feature Highlights](#feature-highlights)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Key Workflows](#key-workflows)
- [Testing & Quality Checks](#testing--quality-checks)
- [Troubleshooting](#troubleshooting)
- [Useful Commands](#useful-commands)
- [Contributing](#contributing)
- [License](#license)

## Overview
- Authentication (register/login/logout) is handled through the Sports Aadhaar backend, with JWTs stored via `SharedPreferences`.
- Athletes can either record a fresh test using the device camera or upload an existing video from the gallery; both paths generate a `TestResult`.
- Results are saved locally (SQLite on desktop/mobile, `SharedPreferences` on web) and synced to the backend when connectivity is detected.
- Pose analysis is stubbed through `PoseDetectionService`, giving engineers a single integration point to swap in MediaPipe/TFLite later.
- The UI is built with Material 3, Google Fonts (Poppins), shared layout widgets (`AppScaffold`, `PrimaryButton`, `ElevationCard`) and supports light/dark modes.

## Feature Highlights
- **Account management** – Register, login, profile refresh, and logout flows rooted in `AppState` (`lib/main.dart`) so routes react to auth state automatically.
- **Video capture & upload** – `RecordTestScreen` uses `camera` while `VideoUploadScreen` uses `image_picker` + `video_player` for previews.
- **Offline-first data** – `LocalDbService` (SQLite/FFI) keeps results even if uploads fail; web falls back to serialized JSON in `SharedPreferences`.
- **Background sync** – `SyncService` checks connectivity via `connectivity_plus` and posts unsynced results to `/tests/upload` with the stored JWT.
- **Pose analysis hook** – `PoseDetectionService.analyzeVideo` currently returns a placeholder payload, giving ML engineers a predictable contract.
- **Theming** – `AppTheme` centralizes Material 3 colors, cards, and inputs; `AppScaffold` adds gradients and animations for auth screens.

## Architecture
```
lib/
├── core/        # Environment config, models, services (API, DB, pose, sync), reusable widgets
├── features/    # Feature-specific screens: auth, home, tests, leaderboard, profile
├── ui/          # Theme + shared UI components (app scaffold, primary button, cards, splash)
├── main.dart    # AppState (auth + sync orchestrator), MultiProvider wiring, routes
└── ...
```

- `AppState` (ChangeNotifier) keeps the logged-in user and kicks off syncs whenever a user signs in.
- `database_factory_initializer.dart` chooses the right SQLite factory: native for Android/iOS, FFI for desktop, and a stub for the web.
- `Env` stores backend endpoints (`lib/core/env.dart`), so no extra dotenv dependency is required.
- Feature directories keep UI logic separated from the low-level services under `core`.

## Tech Stack
- **Flutter** 3.22+/Dart 3.10 (as defined in `pubspec.yaml`)
- **State management**: `provider`
- **Networking**: `dio` with generous timeouts for cold-started Render instances
- **Storage**: `sqflite`/`sqflite_common_ffi`, `shared_preferences`, `flutter_secure_storage`
- **Device APIs**: `camera`, `image_picker`, `video_player`, `path_provider`
- **Connectivity & IDs**: `connectivity_plus`, `uuid`
- **UI/Animation**: `google_fonts`, `flutter_animate`

## Prerequisites
1. Flutter SDK 3.22+ installed and on your `$PATH`.  
2. Android Studio or Xcode command-line tools (for Android/iOS builds).  
3. A device/emulator with camera access for recording flows.  
4. (Optional) Access to the Sports Aadhaar backend or a compatible local server; defaults point to the Render deployment.  
5. CocoaPods (`brew install cocoapods`) if you plan to run the iOS project.

## Getting Started
1. **Clone the repo**
   ```bash
   git clone https://github.com/<org>/antardrishti.git
   cd antardrishti
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Configure platform projects**
   - Android: open `android/` in Android Studio if you need to edit manifests/Gradle.
   - iOS/macOS: run `cd ios && pod install` the first time (CocoaPods must be installed).
4. **Pick a device**
   - Mobile: `flutter devices` to list emulators/physical devices.
   - Web/Desktop: supported for UI exploration, but camera recording is only wired up on mobile.
5. **Run the app**
   ```bash
   flutter run -d <device_id>
   ```
6. **Hot reload & iterate** – Flutter’s hot reload works across auth, recording, and upload screens.

## Environment Configuration
- The only runtime configuration right now is the API base URL in `lib/core/env.dart`:
  ```dart
  class Env {
    static const String apiBaseUrl = 'https://antardrishti-auth-server.onrender.com';
  }
  ```
- Point this to your staging or local server when developing backend features.
- If you need separate builds per environment, create variants of `env.dart` (e.g., `env_dev.dart`) and wire them through a simple `--dart-define` switch.

## Key Workflows
### Authentication
- `AuthService` talks to `/auth/login`, `/auth/register`, and `/profile`.
- Successful responses are serialized via `User.toJson()` and stored with `SharedPreferences` under `_userKey`.
- `AppState` exposes helper methods (`login`, `register`, `logout`, `refreshProfile`) used directly by `LoginScreen`/`RegisterScreen`/`ProfileScreen`.

### Recording & Uploading Tests
1. Pick a test type from `TestListScreen` or via the dropdown on `VideoUploadScreen`.
2. Record with `camera` or choose an existing clip.
3. `VideoService` copies the video into `ApplicationDocumentsDirectory/videos/<timestamp>.mp4`.
4. `PoseDetectionService.analyzeVideo` runs (currently stubbed); replace with MediaPipe/TFLite to produce real metrics.
5. `TestResult` is created and stored via `LocalDbService.insertTestResult`.

### Offline Cache & Sync
- **Local storage**: SQLite (`sqflite` + `sqflite_common_ffi`) on mobile/desktop, JSON in `SharedPreferences` for the web.
- **Sync loop**: `SyncService.syncPendingResults` runs after login/register and after each new result. It checks connectivity before POSTing to `/tests/upload`. Successful uploads mark the record as `TestSyncStatus.uploaded`.
- **Conflict handling**: duplicates are overwritten on insert, so replays are idempotent if you reuse result IDs.

### Pose Detection Integration
- Replace the body of `PoseDetectionService.analyzeVideo` with your inference pipeline.
- Keep the return type (`PoseAnalysisResult`) consistent so existing UI and storage code continue to work.
- Use `PoseAnalysisResult.debugData` to stash raw keypoints/landmarks for future visualization.

## Testing & Quality Checks
- **Unit/widget tests**: `flutter test`
- **Static analysis**: `flutter analyze` (rules configured in `analysis_options.yaml`)
- **Formatting**: `dart format .`
- **Manual QA**: cover login → record → offline sync → profile refresh along with dark/light themes.

## Troubleshooting
- **“Camera access denied”** – Ensure emulator/device has a camera and that you’ve accepted runtime permissions. On Android 13+, confirm `android/app/src/main/AndroidManifest.xml` includes `CAMERA` and `RECORD_AUDIO` (for audio if you enable it later).
- **“Database factory not initialized”** – Desktop builds require `sqflite_common_ffi`; `database_factory_initializer_io.dart` already sets this up, so make sure you import `LocalDbService` only after calling `ensureDatabaseFactoryInitialized()` (already handled in `LocalDbService.db`).
- **“Unable to reach backend”** – Verify `Env.apiBaseUrl`, confirm the Render instance is awake, or point to a local tunnel.
- **“Video fails to save”** – Check available disk space and storage permissions; `VideoService` writes to `ApplicationDocumentsDirectory/videos/`.
- **`camera` on web/desktop** – Not supported; use the gallery upload flow or a native build.

## Useful Commands
```bash
flutter pub get                 # Install dependencies
flutter analyze                 # Static analysis
flutter test                    # Run unit/widget tests
flutter run -d ios              # Launch on a specific device
flutter build apk --release     # Produce a release Android APK
flutter build ipa --no-codesign # Produce an unsigned iOS archive
```

## Contributing
Issues, feature requests, and PRs are welcome. See `CONTRIBUTING.md` for the workflow, coding standards, and review checklist.

## License
A placeholder `LICENSE` file is included. Fill it with the appropriate license text before distributing builds outside your team.
