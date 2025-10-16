import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration
/// 
/// This file loads environment variables and provides a centralized
/// configuration for the EPANSA app.
/// 
/// To use this configuration:
/// 1. Copy .env.example to .env
/// 2. Fill in your actual API keys and configuration values
/// 3. Call AppConfig.initialize() in main() before runApp()

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  static bool _initialized = false;

  /// Initialize the configuration by loading .env file
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
    } catch (e) {
      print('Warning: Could not load .env file: $e');
      print('Using default configuration values');
    }
  }

  // ========================================
  // Remote Agent API Configuration
  // ========================================
  
  /// Base URL of the remote AI agent server
  /// Note: Use 10.0.2.2 for Android emulator to reach host machine's localhost
  static String get agentApiBaseUrl => 
      dotenv.env['AGENT_API_BASE_URL'] ?? 'http://10.0.2.2:5001';

  /// API Key for authenticating requests to the remote agent
  static String get agentApiKey => 
      dotenv.env['AGENT_API_KEY'] ?? 'YOUR_AGENT_API_KEY_HERE';

  /// WebSocket URL for real-time communication
  static String get agentWebSocketUrl => 
      dotenv.env['AGENT_WEBSOCKET_URL'] ?? 'YOUR_AGENT_WEBSOCKET_URL_HERE';

  // ========================================
  // Google OAuth Configuration
  // ========================================

  /// Google OAuth Client ID for Android
  static String get googleOAuthClientIdAndroid => 
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID_ANDROID'] ?? 
      'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com';

  /// Google OAuth Client ID for iOS
  static String get googleOAuthClientIdIos => 
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID_IOS'] ?? 
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  /// Google OAuth Client ID for Web
  static String get googleOAuthClientIdWeb => 
      dotenv.env['GOOGLE_OAUTH_CLIENT_ID_WEB'] ?? 
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  /// Google API Key
  static String get googleApiKey => 
      dotenv.env['GOOGLE_API_KEY'] ?? 'YOUR_GOOGLE_API_KEY_HERE';

  // ========================================
  // Environment Configuration
  // ========================================

  /// Current environment (development, staging, production)
  static String get environment => 
      dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Debug mode flag
  static bool get debugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  // ========================================
  // Feature Flags
  // ========================================

  /// Enable background sync
  static bool get enableBackgroundSync => 
      dotenv.env['ENABLE_BACKGROUND_SYNC']?.toLowerCase() != 'false';

  /// Background sync interval in minutes
  static int get backgroundSyncInterval => 
      int.tryParse(dotenv.env['BACKGROUND_SYNC_INTERVAL'] ?? '30') ?? 30;

  /// Enable voice input
  static bool get enableVoiceInput => 
      dotenv.env['ENABLE_VOICE_INPUT']?.toLowerCase() != 'false';

  /// Require user confirmation for sensitive actions
  static bool get requireUserConfirmation => 
      dotenv.env['REQUIRE_USER_CONFIRMATION']?.toLowerCase() != 'false';

  // ========================================
  // Validation & Helpers
  // ========================================

  /// Check if configuration is valid (not using placeholder values)
  static bool get isConfigured {
    return !agentApiBaseUrl.contains('YOUR_') &&
        !agentApiKey.contains('YOUR_') &&
        !googleOAuthClientIdAndroid.contains('YOUR_') &&
        !googleOAuthClientIdIos.contains('YOUR_');
  }

  /// Get a list of missing configuration keys
  static List<String> get missingConfiguration {
    final List<String> missing = [];
    
    if (agentApiBaseUrl.contains('YOUR_')) {
      missing.add('AGENT_API_BASE_URL');
    }
    if (agentApiKey.contains('YOUR_')) {
      missing.add('AGENT_API_KEY');
    }
    if (googleOAuthClientIdAndroid.contains('YOUR_')) {
      missing.add('GOOGLE_OAUTH_CLIENT_ID_ANDROID');
    }
    if (googleOAuthClientIdIos.contains('YOUR_')) {
      missing.add('GOOGLE_OAUTH_CLIENT_ID_IOS');
    }
    if (googleApiKey.contains('YOUR_')) {
      missing.add('GOOGLE_API_KEY');
    }
    
    return missing;
  }

  /// Print configuration status (for debugging)
  static void printStatus() {
    print('═══════════════════════════════════════');
    print('EPANSA App Configuration Status');
    print('═══════════════════════════════════════');
    print('Environment: $environment');
    print('Debug Mode: $debugMode');
    print('Configured: ${isConfigured ? "✓ YES" : "✗ NO"}');
    
    if (!isConfigured) {
      print('\nMissing Configuration:');
      for (final key in missingConfiguration) {
        print('  ✗ $key');
      }
      print('\nPlease update your .env file or pass');
      print('--dart-define flags when building.');
    } else {
      print('All required configuration keys are set ✓');
    }
    print('═══════════════════════════════════════');
  }
}
