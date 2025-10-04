# Configuration TODO Checklist

Use this checklist to track your configuration progress. Check off items as you complete them.

## Phase 1: Initial Setup ✅ COMPLETE

- [x] Create `.env.example` template
- [x] Create `.env` file
- [x] Create `app_config.dart` configuration loader
- [x] Update `.gitignore` to exclude secrets
- [x] Create configuration documentation

## Phase 2: Remote Agent API Configuration

### Backend Setup
- [ ] Deploy your AI agent server
- [ ] Note the server URL (e.g., https://epansa-agent.yourdomain.com)
- [ ] Generate API key in agent server
- [ ] Configure CORS to allow mobile app requests
- [ ] Test API endpoint with curl/Postman

### Update .env
- [ ] Replace `AGENT_API_BASE_URL` with your actual server URL
- [ ] Replace `AGENT_API_KEY` with your generated API key
- [ ] (Optional) Replace `AGENT_WEBSOCKET_URL` if using WebSocket

## Phase 3: Google Cloud Setup

### Google Cloud Project
- [ ] Go to [Google Cloud Console](https://console.cloud.google.com/)
- [ ] Create new project or select existing one
- [ ] Note your project ID: _______________________

### Enable APIs
- [ ] Enable Google Calendar API
- [ ] Enable Google People API (for contacts)
- [ ] Enable Google Drive API (for Keep/files)

### Android OAuth Setup
- [ ] Get SHA-1 fingerprint for debug keystore
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
- [ ] SHA-1 fingerprint: _______________________
- [ ] Create OAuth 2.0 Client ID for Android
  - Type: Android
  - Package name: `com.example.epansa_app` (TODO: change this!)
  - SHA-1: paste your fingerprint
- [ ] Copy Android Client ID: _______________________
- [ ] Update `GOOGLE_OAUTH_CLIENT_ID_ANDROID` in `.env`

### iOS OAuth Setup
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Note Bundle Identifier: _______________________
- [ ] Create OAuth 2.0 Client ID for iOS
  - Type: iOS
  - Bundle ID: paste your bundle identifier
- [ ] Copy iOS Client ID: _______________________
- [ ] Update `GOOGLE_OAUTH_CLIENT_ID_IOS` in `.env`

### Google API Key
- [ ] Create API Key in Google Cloud Console
- [ ] Restrict key to your required APIs
- [ ] Copy API Key: _______________________
- [ ] Update `GOOGLE_API_KEY` in `.env`

## Phase 4: Optional Services

### Firebase (if using)
- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Add Firebase to your Google Cloud project
- [ ] Add Android app (package: `com.example.epansa_app`)
- [ ] Download `google-services.json`
- [ ] Place in `android/app/google-services.json`
- [ ] Add iOS app (bundle ID from Xcode)
- [ ] Download `GoogleService-Info.plist`
- [ ] Place in `ios/Runner/GoogleService-Info.plist`

### Sentry (if using)
- [ ] Create account at [Sentry.io](https://sentry.io/)
- [ ] Create Flutter project
- [ ] Copy DSN: _______________________
- [ ] Update `SENTRY_DSN` in `.env`

## Phase 5: Platform Configuration ✅ COMPLETE

### Android
- [ ] Open `android/app/build.gradle.kts`
- [ ] Change `applicationId` from `com.example.epansa_app` to your domain
- [ ] Your package name: _______________________
- [x] Update `AndroidManifest.xml` with required permissions:
  - [x] INTERNET
  - [x] SEND_SMS
  - [x] CALL_PHONE
  - [x] READ_CONTACTS
  - [x] WRITE_CONTACTS
  - [x] READ_CALENDAR
  - [x] WRITE_CALENDAR
  - [x] SET_ALARM
  - [x] RECORD_AUDIO (microphone)
  - [x] Storage/Media permissions

### iOS
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Update Bundle Identifier if needed
- [x] Update Display Name to "EPANSA"
- [x] Add usage descriptions to `Info.plist`:
  - [x] NSContactsUsageDescription
  - [x] NSCalendarsUsageDescription
  - [x] NSMicrophoneUsageDescription (for voice)
  - [x] NSPhotoLibraryUsageDescription
  - [x] NSRemindersUsageDescription
  - [x] NSSpeechRecognitionUsageDescription

## Phase 6: Verification

- [ ] Run `./check_config.sh` - all keys should be ✓
- [ ] Run `flutter run` and check console for configuration status
- [ ] Test Google Sign-In flow
- [ ] Test API connection to remote agent
- [ ] Verify background sync works
- [ ] Test voice input (if enabled)

## Phase 7: Production Preparation

- [ ] Create production Google OAuth credentials (separate from dev)
- [ ] Create production API keys for agent server
- [ ] Set up release signing for Android (`android/key.properties`)
- [ ] Configure App Signing in Google Play Console
- [ ] Configure provisioning profiles for iOS
- [ ] Test production build with production credentials
- [ ] Set up CI/CD with encrypted secrets

## Notes

**Important URLs:**
- Google Cloud Console: https://console.cloud.google.com/
- Firebase Console: https://console.firebase.google.com/
- Sentry: https://sentry.io/

**Security Reminders:**
- Never commit `.env` file
- Use different credentials for dev/staging/prod
- Rotate keys regularly
- Keep SHA-1 fingerprints secure

**Current Status:** Run `./check_config.sh` to see what's missing

---

Last updated: _______________
Configured by: _______________
