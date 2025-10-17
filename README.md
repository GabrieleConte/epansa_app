# EPANSA App

**Enhanced Personal Assistant with Natural and Smart Abilities**

A Flutter-based mobile application that provides an AI-powered personal assistant capable of interacting with device features, cloud services, and external tools to help users manage their daily tasks and information.

## Overview

EPANSA is a mobile client application that connects to a remote AI agent server, enabling intelligent automation and assistance on Android and iOS devices. The app acts as a bridge between the user's device capabilities and a powerful backend AI system, providing a seamless personal assistant experience.

### Architecture

The application follows a **client-server architecture**:

- **Mobile Client**: Flutter app running on user's device
  - Handles user interface and interactions
  - Manages local data (contacts, alarms, notes, call logs)
  - Executes device-specific actions (SMS, calls, notifications)
  - Provides authentication and authorization

- **Remote AI Agent**: Backend server (separate repository)
  - Processes natural language commands
  - Integrates with Google ecosystem (Calendar, Search)
  - Indexes and queries user data
  - Orchestrates complex multi-step tasks

## Key Features

### Authentication & Security
- **Google OAuth Integration**: Secure authentication using Google Sign-In
- **JWT Token Management**: Backend communication secured with JWT tokens
- **Permission Handling**: Granular permissions for contacts, SMS, phone, calendar, and notifications

### Chat Interface
- **Natural Language Processing**: Communicate with the AI agent using text
- **Voice Input**: Support for voice commands (planned)
- **Rich Media Display**: Supports text, images, and other media formats
- **Real-time Responses**: Immediate feedback from the AI agent
- **Action Confirmation**: User confirmation required for sensitive operations

### Device Integration

#### Local Data Management
- **Contacts Sync**: Automatically syncs device contacts with backend
- **Call Log Tracking**: Records and syncs phone call history
- **Alarm Management**: Create, edit, and delete device alarms
- **Notes**: Internal note-taking with cloud synchronization

#### Device Actions
- **SMS Operations**: Send text messages via agent commands
- **Phone Calls**: Initiate calls through the assistant
- **Calendar Events**: Create and manage calendar entries
- **Notifications**: Local notifications for alarms and reminders

### Background Synchronization
- **WorkManager (Android)**: Periodic background sync even when app is closed
- **Background Fetch (iOS)**: iOS-compatible background synchronization
- **Smart Sync Strategy**: 
  - Tracks sync status to prevent duplicate uploads
  - Alternating batch sync (5 contacts, then 5 calls, repeat)
  - 10-second delays between API calls to manage server load
  - Intelligent change detection for contacts

### Data Synchronization

The app synchronizes the following data types with the backend:

| Data Type | Direction | Frequency | Purpose |
|-----------|-----------|-----------|---------|
| Contacts | Device → Backend | Background + Manual | Enable agent to recognize contacts |
| Call Logs | Device → Backend | Background + Manual | Provide call history context |
| Alarms | Bidirectional | Real-time | Manage alarms via voice/chat |
| Notes | Bidirectional | Real-time | Personal note management |
| Calendar | Backend Only | N/A | Uses Google Calendar API directly |

## Technical Stack

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences
- **HTTP Client**: Dio

### Backend Integration
- **API Communication**: RESTful HTTP/JSON
- **Authentication**: Google OAuth 2.0 + JWT
- **Base URL**: Configurable via `.env` file
- **Default**: `http://10.0.2.2:5001` (Android emulator)

### Platform-Specific Features
- **Android**: 
  - WorkManager for background tasks
  - SMS/Call platform channels
  - Call log access via `call_log` package
- **iOS**: 
  - Background Fetch
  - Contact access via `flutter_contacts`
  - Notification permissions

## Project Structure

```
lib/
├── core/
│   ├── config/          # App configuration (API URLs, feature flags)
│   └── theme/           # UI theming
├── data/
│   ├── api/             # API client and HTTP communication
│   ├── models/          # Data models (local and API)
│   │   └── api/         # Backend API payload models
│   └── repositories/    # Local data repositories
├── presentation/
│   ├── screens/         # UI screens (Chat, Alarms, Notes)
│   └── widgets/         # Reusable UI components
├── providers/           # State management (Provider pattern)
├── services/            # Business logic and platform channels
└── main.dart            # App entry point
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Android Studio / Xcode (for platform-specific development)
- Google Cloud Project with OAuth credentials
- EPANSA backend server running

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/GabrieleConte/epansa_app.git
   cd epansa_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Configure Google OAuth**
   - Add your Google OAuth client IDs to `.env`
   - Update Android/iOS configuration files as needed

5. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Backend API
AGENT_API_BASE_URL=http://10.0.2.2:5001
USE_MOCK_DATA=false

# Google OAuth
GOOGLE_OAUTH_CLIENT_ID_ANDROID=your_android_client_id
GOOGLE_OAUTH_CLIENT_ID_IOS=your_ios_client_id
GOOGLE_OAUTH_CLIENT_ID_WEB=your_web_client_id

# Features
ENABLE_BACKGROUND_SYNC=true
BACKGROUND_SYNC_INTERVAL=30
```

### Backend Endpoints

The app communicates with the following backend endpoints:

- **Chat**: `POST /chat` - Natural language command processing
- **Contacts**: `POST /add_contact`, `/update_contact`, `/delete_contact`
- **Phone Calls**: `POST /add_telephone`, `/delete_telephone`
- **Alarms**: `POST /add_alarm`, `/update_alarm`, `/delete_alarm`
- **Notes**: `POST /add_note`, `/update_note`, `/delete_note`

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Building for Production

**Android**:
```bash
flutter build apk
# or
flutter build appbundle
```

**iOS**:
```bash
flutter build ios
```

## Features in Development

- Voice input integration
- Enhanced media support in chat
- Offline mode improvements
- Widget for quick access
- Multi-language support

## Known Limitations

### Platform Differences
- Background sync behavior varies between Android (WorkManager) and iOS (Background Fetch)
- SMS sending only supported on Android
- Call log access limited to Android

## Contributing

This is a thesis project. For questions or collaboration opportunities, please contact the repository owner.

## License

This project is part of academic research. License terms to be determined.

## Acknowledgments

- Flutter team for the excellent framework
- Google for OAuth and ecosystem integration
- Open-source community for various packages used in this project

---

**Note**: This app requires a companion backend server (EPANSA Orchestrator) to function. The backend repository is maintained separately.