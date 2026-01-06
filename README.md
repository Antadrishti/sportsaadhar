# SAI Sports Aadhar (Antardrishti)

SAI Sports Aadhar is a digital sports identity platform designed to assess, track, and analyze athlete performance using advanced AI and computer vision technologies.

Powered by **SAI Antardrishti**, this application allows athletes to perform standardized physical tests with automated tracking and analysis.

## Features

- **Digital Identity:** Secure authentication and profile management for athletes.
- **AI-Powered Assessments:**
  - **Vertical Jump:** Measure jump height using video analysis.
  - **Standing Broad Jump:** Automated distance measurement.
  - **Sit and Reach:** Flexibility testing.
  - **Shuttle Run:** Agility tracking.
  - **Sit Ups:** Automated repetition counting.
  - **Run Tracking:** Endurance and sprint tracking with geolocation.
- **Video Analysis:** Integrated video recording and processing using Google Generative AI and ML Kit.
- **Real-time Feedback:** Instant results and performance metrics.
- **Secure Data:** Encrypted local storage and secure backend communication.

## Tech Stack

### Mobile App (Frontend)
- **Framework:** Flutter (Dart)
- **State Management:** Provider / Local State
- **AI/ML:** Google ML Kit (Pose Detection), Google Generative AI (Gemini), Custom Computer Vision
- **Media:** Camera, Video Player, Video Thumbnail
- **Utilities:** Geolocator, Flutter Secure Storage, Flutter Animate

### Backend (Server)
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB (via Mongoose)
- **Authentication:** JWT (JSON Web Tokens), BcryptJS

## Prerequisites

- **Flutter SDK:** >=3.10.1
- **Node.js:** >=14.x
- **MongoDB:** Local instance or Atlas Cloud URI
- **Dart SDK:** Compatible with Flutter version

## Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
```

### 2. Backend Setup
The backend handles user authentication and data persistence.

1. Navigate to the server directory:
   ```bash
   cd server
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in the `server` directory with the following variables:
   ```env
   PORT=5000
   MONGODB_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret_key
   ```
4. Start the server:
   ```bash
   npm run dev
   # OR
   npm start
   ```

### 3. Mobile App Key Setup
1. Return to the root directory:
   ```bash
   cd ..
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Create a `.env` file in the root directory:
   ```env
   # Example variables (adjust based on actual requirements)
   API_URL=http://<your-local-ip>:5000/api
   GEMINI_API_KEY=your_google_ai_studio_key
   ```
   *Note: Ensure your `API_URL` points to your computer's local IP address if running on a physical device or emulator.*

4. Run the application:
   ```bash
   flutter run
   ```

## Project Structure

```
sportsaadharm/
├── lib/                 # Flutter Application Source
│   ├── models/          # Data Models
│   ├── screens/         # UI Screens (Login, Home, Tests)
│   ├── services/        # API and Business Logic
│   ├── theme/           # App Styling and Themes
│   ├── widgets/         # Reusable Widgets
│   └── main.dart        # Entry Point
├── server/              # Node.js Backend Source
│   ├── models/          # Mongoose Schemas
│   ├── routes/          # API Routes
│   ├── index.js         # Server Entry Point
│   └── package.json     # Backend Dependencies
├── android/             # Android Native Code
├── ios/                 # iOS Native Code
├── pubspec.yaml         # Flutter Dependencies
└── README.md            # Project Documentation
```

## Contributing
1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License
[License Type] - See LICENSE file for details.
