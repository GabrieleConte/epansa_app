import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:epansa_app/core/config/app_config.dart';
import 'dart:io' show Platform;

/// Authentication service for Google Sign-In and backend JWT management
class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/contacts.readonly',
      'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/photoslibrary.readonly',
    ],
    serverClientId: Platform.isAndroid 
        ? '519447147425-i8j4dncrgmg4cnjulsehc5if03shvsib.apps.googleusercontent.com'
        : null, // iOS handles this differently
    forceCodeForRefreshToken: true, // Force refresh token on first sign-in
  );

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  AuthService() {
    _initSignIn();
  }

  GoogleSignInAccount? _currentUser;
  bool _isSignedIn = false;
  String? _jwtToken;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _isSignedIn;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userPhotoUrl => _currentUser?.photoUrl;
  String? get jwtToken => _jwtToken;

  Future<void> _initSignIn() async {
    // Try to load JWT token from secure storage
    try {
      _jwtToken = await _secureStorage.read(key: 'jwt_token');
      if (_jwtToken != null) {
        debugPrint('✅ Loaded JWT token from storage');
      }
    } catch (e) {
      debugPrint('Error loading JWT token: $e');
    }

    // Try silent sign-in on initialization (v6 API)
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        _isSignedIn = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Silent sign in failed: $e');
    }

    // Listen to sign-in state changes (v6 API)
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      _isSignedIn = account != null;
      notifyListeners();
    });
  }

  /// Sign in with Google and exchange for backend JWT
  Future<bool> signIn() async {
    try {
      debugPrint('🔵 Attempting Google Sign-In...');
      debugPrint('🔵 Platform: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : "Android")}');
      debugPrint('🔵 serverClientId: ${_googleSignIn.serverClientId ?? "null"}');
      debugPrint('🔵 Package name should be: com.example.epansa_app');
      
      // Use v6 signIn() method
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        debugPrint('❌ Sign-in cancelled by user');
        return false;
      }
      
      debugPrint('✅ Google Sign-in successful: ${account.email}');
      debugPrint('🔍 Checking for server auth code...');
      
      // Get server auth code for backend exchange
      final authCode = await account.serverAuthCode;
      debugPrint('🔍 Server auth code: ${authCode != null ? "✅ Received (${authCode.length} chars)" : "❌ NULL"}');
      
      if (authCode == null) {
        debugPrint('❌ Failed to get server auth code - this might mean:');
        debugPrint('   1. serverClientId not properly configured');
        debugPrint('   2. Web OAuth client not created in Google Console');
        debugPrint('   3. OAuth consent screen not configured');
        debugPrint('⚠️  Attempting to continue without backend auth...');
        
        // For now, let's still mark as signed in locally
        _currentUser = account;
        _isSignedIn = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('was_signed_in', true);
        
        notifyListeners();
        return true; // Return true to allow testing without backend
      }
      
      debugPrint('✅ Got server auth code, exchanging with backend...');
      
      // Exchange auth code with backend for JWT
      final jwt = await _exchangeAuthCode(authCode);
      if (jwt == null) {
        debugPrint('❌ Failed to exchange auth code with backend');
        return false;
      }
      
      debugPrint('✅ Received JWT from backend');
      
      _currentUser = account;
      _isSignedIn = true;
      _jwtToken = jwt;
      
      // Save JWT token securely
      await _secureStorage.write(key: 'jwt_token', value: jwt);
      
      // Save sign in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_signed_in', true);
      
      debugPrint('✅ Sign-in complete and JWT stored');
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      debugPrint('❌ Error signing in: $error');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// Exchange Google auth code for backend JWT token
  Future<String?> _exchangeAuthCode(String authCode) async {
    try {
      final url = '${AppConfig.agentApiBaseUrl}/auth/google/exchange_code';
      final payload = {'auth_code': authCode};
      
      debugPrint('🔍 Sending request to: $url');
      debugPrint('🔍 Payload: $payload');
      
      final response = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500, // Don't throw on 4xx errors
        ),
      );
      
      debugPrint('🔍 Response status: ${response.statusCode}');
      debugPrint('🔍 Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        // Extract JWT from response (adjust based on actual response format)
        final jwt = response.data['access_token'] ?? response.data['token'];
        debugPrint('✅ Extracted JWT: ${jwt != null ? "Success" : "Failed - keys available: ${response.data.keys}"}');
        return jwt as String?;
      }
      
      debugPrint('❌ Backend returned status ${response.statusCode}: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Error exchanging auth code: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _isSignedIn = false;
      _jwtToken = null;
      
      // Clear JWT token
      await _secureStorage.delete(key: 'jwt_token');
      
      // Clear sign in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_signed_in', false);
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error signing out: $error');
    }
  }

  /// Get authentication headers for backend API calls
  Future<Map<String, String>> getAuthHeaders() async {
    if (_jwtToken == null) {
      throw Exception('User not authenticated with backend');
    }

    return {
      'Authorization': 'Bearer $_jwtToken',
      'Content-Type': 'application/json',
    };
  }

  /// Get Google authentication tokens (for Google APIs, not backend)
  Future<Map<String, String>> getGoogleAuthHeaders() async {
    if (_currentUser == null) {
      throw Exception('User not signed in with Google');
    }

    try {
      // Get authentication object (v6 API)
      final auth = await _currentUser!.authentication;
      
      return {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      debugPrint('Error getting Google auth headers: $e');
      rethrow;
    }
  }
}
