# FitGenie

FitGenie is an AI-powered fitness and wellness app built with Flutter. It combines workout planning, wellness sessions, progress tracking, Firebase-backed user data, and a Render-hosted AI backend powered through OpenRouter.

## Features

- Email/password authentication with Firebase Auth
- Password reset from the sign-in screen
- AI chatbot for fitness and wellness guidance
- AI-generated workout recommendations
- AI-generated wellness session ideas
- Workout categories such as cardio, core, mobility, dumbbells, no-equipment, and resistance band
- Guided wellness flows such as breathing, meditation, and neck/shoulder relief
- Progress dashboard with live, synced, and aggregate metrics
- Health data sync support through the Flutter `health` package
- Notification support via Firebase Cloud Messaging
- Workout timers, progress indicators, and exercise flow UI

## Tech Stack

### Frontend

- Flutter
- Dart
- Material Design widgets

### Backend

- Node.js
- Express
- Render
- OpenRouter

### Data and Auth

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Admin SDK for backend token verification

### Device Integrations

- Health Connect / health data via Flutter `health`
- Audio playback via `audioplayers`

## Project Structure

```text
fitgenie/
├─ lib/
│  ├─ main.dart
│  └─ services/
├─ assets/
│  ├─ images/
│  └─ sounds/
├─ backend/
│  ├─ server.js
│  └─ package.json
├─ functions/
│  └─ package.json
├─ android/
├─ ios/
├─ web/
└─ pubspec.yaml
```

## Prerequisites

Before running the app, make sure you have:

- Flutter SDK installed
- Dart SDK installed through Flutter
- Android Studio or VS Code
- Firebase project created
- Render account for backend hosting
- OpenRouter API key
- Android device or emulator for testing

## Flutter Dependencies

Main packages used in this project:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_messaging`
- `health`
- `http`
- `google_fonts`
- `audioplayers`

Install dependencies with:

```bash
flutter pub get
```

## Firebase Setup

### 1. Create a Firebase project

Create a Firebase project in the Firebase Console and enable:

- Authentication
- Firestore Database
- Cloud Messaging

### 2. Configure Authentication

Enable:

- Email/Password sign-in

### 3. Configure Flutter app

Add your Android app in Firebase and download:

- `google-services.json` for Android

Make sure your `lib/firebase_options.dart` is configured with real project values instead of placeholders.

### 4. Android notes

If you use health sync on Android, make sure:

- Health Connect permissions are declared
- The app is tested on a compatible Android device

## AI Backend Setup

FitGenie uses a separate backend hosted on Render instead of Firebase Functions for chatbot and AI content generation.

### Backend endpoints

The backend currently exposes:

- `GET /health`
- `POST /chat`
- `POST /generate-workouts`
- `POST /generate-wellness`

### Render Environment Variables

Set these in your Render service:

```env
OPENROUTER_API_KEY=your_openrouter_key
OPENROUTER_MODEL=openrouter/aurora-alpha
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_service_account_client_email
FIREBASE_PRIVATE_KEY=your_service_account_private_key_with_\n_escaped
OPENROUTER_REFERER=https://your-render-service.onrender.com
OPENROUTER_APP_NAME=FitGenie
```

### Service account setup

To verify Firebase user tokens in the backend:

1. Open Firebase Console
2. Go to `Project settings`
3. Open `Service accounts`
4. Generate a new private key
5. Copy:
   - `client_email` into `FIREBASE_CLIENT_EMAIL`
   - `private_key` into `FIREBASE_PRIVATE_KEY`
6. Replace line breaks in `private_key` with `\n`

## Running the Backend Locally

From the project root:

```bash
cd backend
npm install
npm start
```

By default, the backend runs on:

```text
http://localhost:8080
```

Health check:

```text
http://localhost:8080/health
```

## Running the Flutter App

Run the app with your backend endpoint passed through `dart-define`:

```bash
flutter run --dart-define=FITGENIE_CHAT_ENDPOINT=https://your-render-service.onrender.com/chat
```

If you are testing locally against a local backend, replace the URL accordingly.

## Authentication Flow

Users can:

- Register with email and password
- Sign in with email and password
- Reset their password from the sign-in screen
- Sign out from the app

User profile and starter data are stored in Firestore on registration.

## Chatbot Flow

1. User sends a message from the app
2. Flutter sends the request to the Render backend
3. The backend verifies the Firebase ID token
4. The backend calls OpenRouter
5. The response is returned to the app
6. Chat history is stored in Firestore

## Progress and Data Model

The app separates progress information into:

- `live` stats
- `synced` device stats
- `aggregate` stats

This helps distinguish:

- workout activity recorded inside the app
- health/device synced values
- long-term totals and history

AI-generated content also includes source metadata such as:

- `manual`
- `health_sync`
- `ai_generated`
- `live_session`

## Notifications

FitGenie includes Firebase Cloud Messaging integration for notifications.

Current notification-related work includes:

- token handling
- client subscription flow
- motivational alert groundwork

You may still need platform-specific notification configuration for full production behavior.

## Assets

Project assets include:

- app logo
- workout and wellness images
- breathing and recovery icons
- beep sound for timers

Defined in `pubspec.yaml`.

## Common Commands

### Get packages

```bash
flutter pub get
```

### Run the app

```bash
flutter run --dart-define=FITGENIE_CHAT_ENDPOINT=https://your-render-service.onrender.com/chat
```

### Analyze

```bash
flutter analyze
```

### Format

```bash
dart format lib
```

### Build APK

```bash
flutter build apk --debug
```

## Known Notes

- The project still contains a `functions/` folder, but the active AI backend flow uses `backend/` on Render.
- iOS setup is not fully testable without a Mac.
- Some analyzer output is currently info-level style/deprecation warnings rather than blocking compile errors.
- Health sync depends on platform permissions and device support.

## Roadmap Ideas

- Improve small-screen responsiveness across all pages
- Add stronger Firestore security rules
- Add backend rate limiting
- Improve notification scheduling
- Expand automated tests
- Split `lib/main.dart` into smaller modules
- Add richer AI coaching and plan personalization

## License

This project is currently private and not published to pub.dev.
