# Configuration Directory

This directory contains the application configuration files.

## Files

### `app_config.dart`
Central configuration class that loads environment variables using Dart's `String.fromEnvironment()` compile-time constants.

**Usage:**
```dart
import 'package:epansa_app/core/config/app_config.dart';

// Access configuration values
final apiUrl = AppConfig.agentApiBaseUrl;
final apiKey = AppConfig.agentApiKey;

// Check if app is properly configured
if (!AppConfig.isConfigured) {
  print('Missing configuration: ${AppConfig.missingConfiguration}');
}

// Print configuration status (useful during development)
AppConfig.printStatus();
```

## Configuration Methods

### Method 1: Using .env file (Development)
1. Copy `.env.example` to `.env` in project root
2. Fill in your actual values
3. Use a package like `flutter_dotenv` to load at runtime (requires adding to pubspec.yaml)

### Method 2: Using --dart-define (Recommended for Production)
Pass values at build/run time:

```bash
flutter run \
  --dart-define=AGENT_API_BASE_URL=https://your-server.com \
  --dart-define=AGENT_API_KEY=your_key
```

### Method 3: Using --dart-define-from-file (Flutter 3.7+)
Create a `config.json` file and pass it:

```bash
flutter run --dart-define-from-file=config.json
```

## Important Notes

- **Never commit** `.env` or any file with actual API keys to version control
- The `.gitignore` file is already configured to exclude these files
- Use different API keys for development, staging, and production environments
- Configuration values are compile-time constants, so changes require app rebuild

## See Also

- `../../.env.example` - Template for environment variables
- `../../CONFIGURATION.md` - Comprehensive configuration guide
