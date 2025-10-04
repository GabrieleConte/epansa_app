# Configuration Summary - Quick Reference

## 📋 What You Need to Configure

### 1️⃣ **Remote Agent API** (Required)
- [ ] `AGENT_API_BASE_URL` - Your AI agent server URL
- [ ] `AGENT_API_KEY` - Authentication key for your agent
- [ ] `AGENT_WEBSOCKET_URL` - WebSocket endpoint (optional)

**Where to get:** Deploy your agent server or contact your backend team

---

### 2️⃣ **Google OAuth** (Required)
- [ ] `GOOGLE_OAUTH_CLIENT_ID_ANDROID` - Android OAuth Client ID
- [ ] `GOOGLE_OAUTH_CLIENT_ID_IOS` - iOS OAuth Client ID  
- [ ] `GOOGLE_API_KEY` - Google API Key

**Where to get:** [Google Cloud Console](https://console.cloud.google.com/)

**Required APIs to enable:**
- Google Calendar API
- Google People API (contacts)
- Google Drive API (for Keep/files)

**Android SHA-1 fingerprint:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

### 3️⃣ **Optional Services**

#### Firebase (Push notifications, analytics)
- [ ] Download `google-services.json` → `android/app/`
- [ ] Download `GoogleService-Info.plist` → `ios/Runner/`

**Where to get:** [Firebase Console](https://console.firebase.google.com/)

#### Sentry (Error tracking)
- [ ] `SENTRY_DSN` - Sentry project DSN

**Where to get:** [Sentry.io](https://sentry.io/)

---

## 🚀 Quick Setup (3 steps)

### Step 1: Create your .env file
```bash
cp .env.example .env
```

### Step 2: Fill in the values
Edit `.env` and replace all placeholders with your actual credentials

### Step 3: Verify
```bash
./check_config.sh
```

---

## 🏗️ Building the App

### Development
```bash
flutter run
```

### Production (with config)
```bash
flutter build apk \
  --dart-define=AGENT_API_BASE_URL=https://your-server.com/api \
  --dart-define=AGENT_API_KEY=your_key \
  --dart-define=GOOGLE_OAUTH_CLIENT_ID_ANDROID=your_client_id
```

---

## 📁 Files Created

| File | Purpose |
|------|---------|
| `.env.example` | Template with all configuration keys |
| `lib/core/config/app_config.dart` | Configuration loader class |
| `CONFIGURATION.md` | Complete setup guide |
| `check_config.sh` | Verification script |
| `.gitignore` | Updated to exclude secrets |

---

## ⚠️ Security Reminders

- ✅ `.env` is in `.gitignore` - never commit it
- ✅ Use different keys for dev/staging/prod
- ✅ Rotate keys if they may be compromised
- ✅ Store production keys in CI/CD secrets

---

## 🆘 Need Help?

1. Run `./check_config.sh` to see what's missing
2. Read `CONFIGURATION.md` for detailed instructions
3. Check `lib/core/config/README.md` for usage examples

---

## 📝 Current Status

Run the check script to see your configuration status:
```bash
./check_config.sh
```

The app will also show configuration status when you run it.
