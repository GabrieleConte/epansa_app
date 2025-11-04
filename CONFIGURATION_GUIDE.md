# Configuration Guide

This guide explains how to set up all necessary environments and configuration files for the EPANSA app project.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Google Cloud Console Setup](#google-cloud-console-setup)
3. [Firebase Console Setup](#firebase-console-setup)
4. [Environment Variables Configuration](#environment-variables-configuration)
5. [Android Configuration](#android-configuration)
6. [Development vs Production Environments](#development-vs-production-environments)
7. [Verification](#verification)

---

## Prerequisites

Before starting, ensure you have:

- Flutter SDK 3.9.2 or higher installed
- Android Studio with Android SDK
- A Google Cloud Platform account
- A Firebase project created
- Access to the EPANSA backend server

---

## Google Cloud Console Setup

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Note your Project ID

### 2. Enable Required APIs

Navigate to "APIs & Services" > "Library" and enable:

- Google Calendar API
- Google Contacts API
- Google Drive API
- Google Photos Library API
- Google Sign-In API

### 3. Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Select "External" user type
3. Fill in required information:
   - App name: EPANSA
   - User support email: your email
   - Developer contact information: your email
4. Add scopes:
   - `email`
   - `https://www.googleapis.com/auth/calendar.readonly`
   - `https://www.googleapis.com/auth/contacts.readonly`
   - `https://www.googleapis.com/auth/drive.readonly`
   - `https://www.googleapis.com/auth/photoslibrary.readonly`
5. Add test users (if in testing mode)
6. Save and continue

### 4. Create OAuth 2.0 Credentials

#### Android OAuth Client

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Android"
4. Enter:
   - Name: EPANSA Android
   - Package name: `com.example.epansa_app`
   - SHA-1 certificate fingerprint: (see instructions below)
5. Save the Client ID

#### Web OAuth Client

1. Create another OAuth client ID
2. Select "Web application"
3. Enter:
   - Name: EPANSA Web
   - Authorized redirect URIs: (leave empty for now)
4. Save both the Client ID and Client Secret

#### iOS OAuth Client (if targeting iOS)

1. Create another OAuth client ID
2. Select "iOS"
3. Enter:
   - Name: EPANSA iOS
   - Bundle ID: `com.example.epansaApp`
4. Save the Client ID

---

## Firebase Console Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or link existing Google Cloud project
3. Follow the setup wizard

### 2. Add Android App to Firebase

1. Click "Add app" > Android icon
2. Enter package name: `com.example.epansa_app`
3. Enter app nickname: EPANSA
4. Download `google-services.json`
5. Place the file in `android/app/google-services.json`

### 3. Add SHA-1 Certificate Fingerprints

You need to add SHA-1 fingerprints for both debug and release builds.

#### Get Debug SHA-1

On Windows:
```bash
cd android
gradlew signingReport
```

On macOS/Linux:
```bash
cd android
./gradlew signingReport
```

Or using keytool directly:

Windows:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

macOS/Linux:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Add to Firebase

1. In Firebase Console, go to Project Settings
2. Select your Android app
3. Click "Add fingerprint"
4. Paste your SHA-1 certificate
5. Repeat for each developer's debug certificate
6. Later, add your release certificate before publishing

### 4. Download Updated google-services.json

After adding SHA-1 fingerprints:

1. Download the updated `google-services.json` from Firebase Console
2. Replace the file in `android/app/google-services.json`

---

## Environment Variables Configuration

### 1. Create .env File

Copy the example environment file:

```bash
cp .env.example .env
```

If `.env.example` doesn't exist, create `.env` manually with the content below.

### 2. Configure Development Environment

Edit `.env` with your development values:

```env
# EPANSA App Configuration

# Backend API Configuration
AGENT_API_BASE_URL=http://10.0.2.2:5000
USE_MOCK_DATA=false

# Google OAuth Configuration
GOOGLE_OAUTH_CLIENT_ID_ANDROID=your-android-client-id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_ID_IOS=your-ios-client-id.apps.googleusercontent.com
GOOGLE_OAUTH_CLIENT_ID_WEB=your-web-client-id.apps.googleusercontent.com
GOOGLE_API_KEY=your-google-api-key

# Environment Settings
ENVIRONMENT=development
DEBUG_MODE=true

# Feature Flags
ENABLE_BACKGROUND_SYNC=true
BACKGROUND_SYNC_INTERVAL=30
ENABLE_VOICE_INPUT=true
REQUIRE_USER_CONFIRMATION=true

# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_APP_ID_ANDROID=your-android-app-id
FIREBASE_APP_ID_IOS=your-ios-app-id
```

### 3. Important Notes

**DO NOT include these in .env:**

- `AGENT_API_KEY` - Backend should use JWT authentication
- `GOOGLE_OAUTH_CLIENT_SECRET_WEB` - Backend only, never in mobile app

These are server-side secrets and should never be bundled in the mobile application.

### 4. Obtain Configuration Values

#### AGENT_API_BASE_URL

- Development: `http://10.0.2.2:5000` (Android emulator to localhost)
- Development (physical device): Your computer's local IP, e.g., `http://192.168.1.100:5000`
- Production: Your production backend URL, e.g., `https://api.epansa.com`

#### Google OAuth Client IDs

Found in Google Cloud Console > APIs & Services > Credentials:

- Android Client ID: From the Android OAuth client you created
- iOS Client ID: From the iOS OAuth client you created
- Web Client ID: From the Web OAuth client you created

#### GOOGLE_API_KEY

Found in Google Cloud Console > APIs & Services > Credentials > API Keys

Important: Restrict this API key:
1. Click on the API key
2. Under "Application restrictions", select "Android apps"
3. Add package name: `com.example.epansa_app`
4. Add SHA-1 fingerprint
5. Under "API restrictions", select "Restrict key" and choose the APIs you enabled

#### Firebase IDs

Found in Firebase Console > Project Settings:

- Project ID: Listed at the top
- App IDs: Under "Your apps" section for Android and iOS

---

## Android Configuration

### 1. Verify Package Name

Check that `android/app/build.gradle.kts` contains:

```kotlin
android {
    namespace = "com.example.epansa_app"
    
    defaultConfig {
        applicationId = "com.example.epansa_app"
        // ...
    }
}
```

### 2. Verify google-services.json Location

Ensure the file is at: `android/app/google-services.json`

### 3. Verify Gradle Configuration

Check that `android/build.gradle.kts` includes:

```kotlin
dependencies {
    classpath("com.google.gms:google-services:4.3.15")
}
```

And `android/app/build.gradle.kts` includes:

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

---

## Development vs Production Environments

### Development Setup

Use `.env` with development values:

```env
AGENT_API_BASE_URL=http://10.0.2.2:5000
ENVIRONMENT=development
DEBUG_MODE=true
```

Run with:
```bash
flutter run
```

### Production Setup

Create `.env.production` with production values:

```env
AGENT_API_BASE_URL=https://api.epansa.com
ENVIRONMENT=production
DEBUG_MODE=false
ENABLE_BACKGROUND_SYNC=true
BACKGROUND_SYNC_INTERVAL=30
```

**Important for Production:**

1. Generate a release keystore:
```bash
keytool -genkey -v -keystore ~/release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

2. Create `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=release
storeFile=/path/to/release-keystore.jks
```

3. Get release SHA-1:
```bash
keytool -list -v -keystore ~/release-keystore.jks -alias release
```

4. Add release SHA-1 to Firebase Console

5. Download updated `google-services.json`

6. Build release:
```bash
cp .env.production .env
flutter build appbundle --release
```

---

## Verification

### 1. Verify Flutter Setup

```bash
flutter doctor
```

Ensure all items are checked, especially:
- Flutter SDK
- Android toolchain
- Android Studio

### 2. Verify Dependencies

```bash
flutter pub get
```

Should complete without errors.

### 3. Verify Configuration Loading

Run the app in debug mode:
```bash
flutter run
```

Check the console output for:
- Configuration status messages
- No errors about missing configuration
- Successful initialization of services

### 4. Test Google Sign-In

1. Launch the app on an emulator with Google Play Services
2. Tap "Sign in with Google"
3. Select a Google account
4. Grant permissions
5. Verify successful sign-in

If sign-in fails, check:
- SHA-1 certificate is added to Firebase Console
- `google-services.json` is up to date
- Package name matches everywhere
- OAuth consent screen is configured
- Test user is added (if in testing mode)

### 5. Check Logs for Errors

Enable verbose logging:
```bash
flutter run --verbose
```

And check Android logs:
```bash
adb logcat | grep -i "google\|sign\|epansa"
```

---

## Common Issues

### "Developer Error" during Google Sign-In

Cause: SHA-1 fingerprint not added to Firebase Console or outdated `google-services.json`

Solution:
1. Verify SHA-1 is added in Firebase Console
2. Download updated `google-services.json`
3. Replace the file in `android/app/`
4. Run `flutter clean && flutter pub get`
5. Rebuild and run

### "Google Play Services not available"

Cause: Emulator doesn't have Google Play Services

Solution: Create a new AVD with a system image that has the Play Store icon

### Package Name Mismatch

Cause: Package name differs between configurations

Solution: Verify package name is `com.example.epansa_app` in:
- `android/app/build.gradle.kts`
- `google-services.json`
- Firebase Console
- Google Cloud Console

### Configuration Not Loading

Cause: `.env` file missing or not in assets

Solution:
1. Ensure `.env` exists in project root
2. Verify `pubspec.yaml` includes:
```yaml
flutter:
  assets:
    - .env
```
3. Run `flutter pub get`

---

## Security Notes

### What Should NOT Be Committed to Git

The following files are in `.gitignore` and should NEVER be committed:

- `.env` - Contains environment-specific configuration
- `android/app/google-services.json` - Contains Firebase configuration
- `android/key.properties` - Contains release keystore credentials
- `*.keystore`, `*.jks` - Keystore files

### What CAN Be Committed

- `.env.example` - Template without actual values
- Configuration documentation
- Build configuration files (gradle files)

### Sharing Configuration with Team

For private repositories with trusted team members:

1. Share `google-services.json` securely (email, secure file sharing)
2. Each developer adds their own SHA-1 to Firebase Console
3. Each developer creates their own `.env` based on `.env.example`
4. Backend credentials are managed separately and never in the app

---

## Getting Help

If you encounter issues:

1. Check the main README.md for general setup
2. Review the Troubleshooting section in README.md
3. Verify all steps in this guide
4. Check Flutter and Firebase documentation
5. Contact the project maintainer

---

## Summary Checklist

Before running the app, ensure:

- [ ] Flutter SDK installed and `flutter doctor` passes
- [ ] Google Cloud project created
- [ ] Required APIs enabled in Google Cloud Console
- [ ] OAuth consent screen configured
- [ ] OAuth credentials created (Android, Web, iOS)
- [ ] Firebase project created
- [ ] Android app added to Firebase
- [ ] SHA-1 certificate(s) added to Firebase
- [ ] `google-services.json` downloaded and placed correctly
- [ ] `.env` file created with correct values
- [ ] Dependencies installed with `flutter pub get`
- [ ] Android emulator with Google Play Services available
- [ ] Backend server running (if not using mock data)

Once all items are checked, you're ready to run the app with `flutter run`.
