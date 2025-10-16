# EPANSA App - AI Coding Assistant Instructions

## Project Overview
EPANSA is a Flutter mobile app implementing an AI-powered personal assistant. The app acts as a **mobile client** that communicates with a **remote AI agent server** via API. The agent can interact with Google ecosystem tools (calendar, search) and send commands back to the app for device-specific actions (SMS, calls, local files, alarms).

**Key Architecture**: Client-server model where the mobile app is the UI/execution layer and the remote agent is the intelligence layer.

## Project State: Active Development
- ✅ **Authentication**: Google Sign-In implemented and working
- ✅ **Chat UI**: Basic chat interface with message display
- ✅ **Services Layer**: AlarmService, SMSService, CallService, CalendarEventService, SyncService
- ✅ **Background Sync**: WorkManager (Android) + Background Fetch (iOS) - syncs even when app closed
- ✅ **Platform Channels**: SMS sending (Android), native integrations ready
- ✅ **Permissions**: Contacts, Calendar, SMS, Phone, Notifications all handled
- ⚠️ **Using Mock Data**: Agent API responses are currently mocked (see Critical TODOs)
- ⚠️ **Manual Alarm Input**: No UI for users to manually create/manage alarms yet

## Planned Architecture (Not Yet Implemented)
Based on README.md, the app will need:

1. ~~**Authentication Layer**: Google OAuth integration to send tokens to remote agent~~ ✅ DONE
2. **API Client**: HTTP communication with remote agent server (needs endpoint configuration) ⚠️ MOCKED
3. ~~**Local Action Handlers**: Platform channels for SMS, calls, file access, alarms~~ ✅ DONE
4. ~~**Sync Service**: Background sync for contacts, tasks, alarms to remote agent~~ ✅ DONE
5. ~~**Chat UI**: Text/voice input with media display support~~ ✅ DONE (text only, voice TBD)
6. ~~**Confirmation UI**: User approval system for sensitive actions~~ ✅ DONE

## Current Architecture (Implemented)
```
lib/
  core/           # Constants, themes (app_config.dart, app_theme.dart)
  data/           
    api/          # AgentApiClient (CURRENTLY MOCKED)
    models/       # ChatMessage, PendingAction models
  providers/      # ChatProvider (state management with ChangeNotifier)
  screens/        # SignInScreen, SyncSetupScreen, ChatScreen
  services/       # AlarmService, SMSService, CallService, CalendarEventService, SyncService
  widgets/        # Reusable UI components
  main.dart       # App entry point with routing
```

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

### Known Limitations
- **Reading System Alarms**: Android security prevents reading alarms from other apps (Clock app)
  - Even with root access, modern Clock apps don't expose alarm data via ContentProviders
  - AlarmManager system service is not queryable by third-party apps
  - Current implementation only supports alarms created by this app
  - Documented in `lib/services/alarm_service.dart` and `ALARM_READING_TEST_GUIDE.md`

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

#### High Priority - Backend Integration
1. **Connect Real Backend API**: 
   - Replace mock implementation in `lib/data/api/agent_api_client.dart`
   - Configure real backend endpoint in `lib/core/app_config.dart`
   - Implement proper HTTP client (dio/http package)
   - Send Google OAuth tokens to backend for authentication
   - Handle real API responses and errors

2. **Parse Backend Responses**:
   - Define proper response models for agent actions
   - Parse JSON responses into typed models
   - Remove all mock data generation
   - Implement proper error handling for network failures

3. **Action Recognition System**:
   - Implement backend response parsing to detect action requests
   - Map backend action types to local services (SMS, calls, alarms, etc.)
   - Remove hardcoded mock action responses in `ChatProvider`

#### High Priority - UI Features
4. **Alarm Management Screen**:
   - Create UI for users to manually create/edit/delete alarms
   - Add alarm list view showing all user-configured alarms
   - Integrate with `AlarmService` to actually set device alarms
   - Send user-created alarms to backend for agent awareness
   - Add navigation from chat screen to alarm management

#### Medium Priority - Infrastructure
5. Change Android `applicationId` from `com.example.epansa_app` to production domain
6. Add signing config for Android release builds (`android/app/build.gradle.kts`)
7. Add environment-based configuration (dev/staging/prod)
8. Implement proper logging system (instead of debugPrint)

#### Low Priority - Polish
9. Add voice input support in chat UI
10. Improve error messages and user feedback
11. Add loading states for all async operations
12. Implement offline mode handling

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

## Do NOT create summary documents