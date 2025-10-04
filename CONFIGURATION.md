# EPANSA App Configuration Guide

## Overview
This guide explains how to configure the EPANSA app with the necessary API keys and credentials.

## Required Configuration

### 1. Remote Agent API
The app needs to communicate with your remote AI agent server.

**Required:**
- `AGENT_API_BASE_URL` - The base URL of your agent server API
- `AGENT_API_KEY` - API key for authenticating requests to your agent
- `AGENT_WEBSOCKET_URL` - WebSocket URL for real-time communication (optional)

**Where to get these:**
- Deploy your agent server and note the URL
- Generate an API key in your agent server's admin panel
- Configure your agent server to accept requests from the mobile app

### 2. Google OAuth Credentials
The app uses Google Sign-In to access Google ecosystem services (Calendar, Keep, etc.)

**Required:**
- `GOOGLE_OAUTH_CLIENT_ID_ANDROID` - OAuth client ID for Android
- `GOOGLE_OAUTH_CLIENT_ID_IOS` - OAuth client ID for iOS
- `GOOGLE_API_KEY` - General Google API key

**How to get these:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Google Calendar API
   - Google People API (for contacts)
   - Google Drive API (if accessing Keep/files)
4. Go to "Credentials" section
5. Create OAuth 2.0 Client IDs:
   - **Android**: Select "Android" type, enter package name and SHA-1 certificate fingerprint
   - **iOS**: Select "iOS" type, enter bundle identifier
6. Create an API Key (restrict it to your required APIs)

**Get SHA-1 for Android:**
```bash
# For debug keystore:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release keystore (when you create one):
keytool -list -v -keystore /path/to/release.keystore -alias your_alias
```

### 3. Optional Services

#### Firebase (for push notifications, analytics)
If you want to use Firebase:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a project or add Firebase to your Google Cloud project
3. Add Android app (package: `com.example.epansa_app` - update this!)
4. Add iOS app (bundle ID from Xcode)
5. Download config files:
   - `google-services.json` for Android → place in `android/app/`
   - `GoogleService-Info.plist` for iOS → place in `ios/Runner/`

#### Sentry (for error tracking)
1. Create account at [Sentry.io](https://sentry.io/)
2. Create a new project for Flutter
3. Copy the DSN and add to `.env`

## Setup Instructions

### Step 1: Copy the example environment file
```bash
cp .env.example .env
```

### Step 2: Fill in your actual values
Edit `.env` and replace all placeholder values with your actual credentials.

**Example:**
```bash
# Before (placeholder)
AGENT_API_BASE_URL=https://your-agent-server.example.com/api/v1

# After (your actual value)
AGENT_API_BASE_URL=https://epansa-agent.mydomain.com/api/v1
```

### Step 3: Verify configuration
The app will check configuration at startup. You can also verify by checking the console output when running the app.

## Building with Configuration

### Development Build
```bash
flutter run
```

### Production Build with Environment Variables
You can pass configuration at build time using `--dart-define`:

```bash
flutter build apk \
  --dart-define=AGENT_API_BASE_URL=https://your-server.com/api \
  --dart-define=AGENT_API_KEY=your_key \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID_ANDROID=your_client_id \
  --dart-define=ENVIRONMENT=production \
  --dart-define=DEBUG_MODE=false
```

### Using dart-define-from-file (Flutter 3.7+)
Create a JSON file with your configuration:

**config.json:**
```json
{
  "AGENT_API_BASE_URL": "https://your-server.com/api",
  "AGENT_API_KEY": "your_key",
  "GOOGLE_OAUTH_CLIENT_ID_ANDROID": "your_client_id.apps.googleusercontent.com",
  "ENVIRONMENT": "production"
}
```

Build with:
```bash
flutter build apk --dart-define-from-file=config.json
```

## Security Best Practices

1. **Never commit `.env` file** - It's in `.gitignore`, keep it that way
2. **Use different API keys for dev/staging/prod** - Easier to revoke if compromised
3. **Rotate keys regularly** - Especially if they may have been exposed
4. **Use environment variables in CI/CD** - Don't store secrets in repository
5. **Restrict API keys** - Use Google Cloud Console to restrict keys to specific APIs and domains

## Platform-Specific Configuration

### Android
Update package name from default:
- Edit `android/app/build.gradle.kts`
- Change `applicationId` from `"com.example.epansa_app"` to your domain

### iOS
Update bundle identifier:
- Open `ios/Runner.xcworkspace` in Xcode
- Select Runner target → General → Bundle Identifier
- Change from default to your identifier

## Troubleshooting

### Configuration not loading
- Ensure `.env` file exists in project root
- Check file permissions
- Verify no typos in variable names

### Google Sign-In not working
- Verify package name/bundle ID matches OAuth credentials
- For Android: Double-check SHA-1 fingerprint is registered
- Ensure required Google APIs are enabled in Cloud Console

### Agent API connection fails
- Check if agent server is running and accessible
- Verify base URL includes protocol (https://)
- Test API endpoint with curl/Postman first
- Check firewall rules allow mobile app connections

## Getting Help

If you need help with configuration:
1. Check this guide thoroughly
2. Review `.env.example` for all available options
3. Check Google Cloud Console for API quotas/errors
4. Review agent server logs for authentication issues
