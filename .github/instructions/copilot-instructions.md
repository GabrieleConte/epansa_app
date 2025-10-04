# EPANSA App - AI Coding Assistant Instructions

## Project Overview
EPANSA is a Flutter mobile app implementing an AI-powered personal assistant. The app acts as a **mobile client** that communicates with a **remote AI agent server** via API. The agent can interact with Google ecosystem tools (calendar, notes, search) and send commands back to the app for device-specific actions (SMS, calls, local files, alarms).

**Key Architecture**: Client-server model where the mobile app is the UI/execution layer and the remote agent is the intelligence layer.

## Project State: Early Development
- Currently contains **default Flutter template** (`lib/main.dart` with counter demo)
- No custom architecture, services, or UI components implemented yet
- **pubspec.yaml** has minimal dependencies (only `cupertino_icons` + test packages)
- This is a **greenfield project** - planned features are documented in README but not yet built

## Planned Architecture (Not Yet Implemented)
Based on README.md, the app will need:

1. **Authentication Layer**: Google OAuth integration to send tokens to remote agent
2. **API Client**: HTTP communication with remote agent server (needs endpoint configuration)
3. **Local Action Handlers**: Platform channels for SMS, calls, file access, alarms
4. **Sync Service**: Background sync for contacts, tasks, notes, alarms to remote agent
5. **Chat UI**: Text/voice input with media display support
6. **Confirmation UI**: User approval system for sensitive actions

## Development Guidelines

### When Adding New Features
- **Platform-specific code**: Use method channels for iOS/Android native functionality
  - SMS/calls: Requires permissions in `AndroidManifest.xml` and `Info.plist`
  - Background sync: Consider WorkManager (Android) / Background Fetch (iOS)
- **State management**: Choose provider/bloc/riverpod early (not yet decided)
- **API integration**: Base URL should be configurable (dev/staging/prod environments)
- **Google OAuth**: Use `google_sign_in` package, store tokens securely (flutter_secure_storage)

### Project Structure (Recommended)
```
lib/
  core/           # Constants, themes, utils, DI
  data/           # API clients, repositories, models
  domain/         # Business logic, use cases
  presentation/   # UI screens, widgets, state
  services/       # Platform channels, background services
```

### Build & Run
- **Run app**: `flutter run` (targets connected device/emulator)
- **Hot reload**: Press `r` in terminal or save files
- **Hot restart**: Press `R` (clears state)
- **Tests**: `flutter test` (currently has basic widget test in `test/widget_test.dart`)
- **Build Android**: `flutter build apk` or `flutter build appbundle`
- **Build iOS**: `flutter build ios` (requires macOS + Xcode)

### Platform Configuration
- **Android**: 
  - Package: `com.example.epansa_app` (TODO: change from example domain)
  - Min SDK: Uses Flutter default (check `android/app/build.gradle.kts`)
  - Permissions: Add to `android/app/src/main/AndroidManifest.xml`
- **iOS**: 
  - Display name: "Epansa App" 
  - Bundle ID: Set in Xcode project
  - Permissions: Add usage descriptions to `ios/Runner/Info.plist`

### Code Style
- **Linting**: Uses `flutter_lints` package (strict Flutter recommended rules)
- **Analysis**: Run `flutter analyze` before commits
- **Formatting**: `dart format .` to auto-format code

### Critical TODOs in Codebase
1. Change Android `applicationId` from `com.example.epansa_app` to production domain
2. Remove default counter demo code in `lib/main.dart`
3. Add signing config for Android release builds (`android/app/build.gradle.kts`)
4. Configure API endpoint and environment variables
5. Add required permissions for SMS, calls, contacts, calendar access

### Security Considerations
- **OAuth tokens**: Never log or hardcode, use secure storage
- **User confirmation**: Required for SMS, calls, and potentially destructive actions
- **Data sync**: Encrypt sensitive data before sending to remote agent
- **API communication**: Use HTTPS, implement certificate pinning for production

### Testing Strategy
- Widget tests for UI components
- Integration tests for agent communication flow
- Mock API responses during development
- Test platform channels with mock method channel handlers

## When Unsure
- Consult README.md for feature requirements
- Flutter documentation for mobile-specific patterns
- No existing code patterns to follow yet - establish new conventions thoughtfully
