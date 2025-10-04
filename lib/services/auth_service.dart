import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epansa_app/core/config/app_config.dart';

/// Authentication service for Google Sign-In
class AuthService extends ChangeNotifier {
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // Initialize GoogleSignIn with platform-specific config
    _googleSignIn = GoogleSignIn(
      // For iOS/Android: No clientId needed (uses native config from Info.plist)
      // For Web: use clientId with web client ID
      clientId: kIsWeb ? AppConfig.googleOAuthClientIdWeb : null,
      scopes: [
        'email',
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/contacts.readonly',
      ],
    );
    _initSignIn();
  }

  GoogleSignInAccount? _currentUser;
  bool _isSignedIn = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _isSignedIn;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userPhotoUrl => _currentUser?.photoUrl;

  Future<void> _initSignIn() async {
    // Check if user was previously signed in
    final prefs = await SharedPreferences.getInstance();
    final wasSignedIn = prefs.getBool('was_signed_in') ?? false;

    if (wasSignedIn) {
      // Try silent sign in
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
    }

    // Listen for sign in changes
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      _isSignedIn = account != null;
      notifyListeners();
    });
  }

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      debugPrint('🔵 GoogleSignIn.signIn() called');
      debugPrint('🔵 Platform: ${kIsWeb ? "Web" : "iOS/Android"}');
      debugPrint('🔵 Client ID configured: ${kIsWeb ? AppConfig.googleOAuthClientIdWeb : AppConfig.googleOAuthClientIdIos}');
      
      final account = await _googleSignIn.signIn();
      
      debugPrint('🔵 Sign-in account result: ${account?.email ?? "null"}');
      
      if (account != null) {
        _currentUser = account;
        _isSignedIn = true;
        
        // Save sign in state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('was_signed_in', true);
        
        debugPrint('✅ Sign-in successful: ${account.email}');
        notifyListeners();
        return true;
      }
      debugPrint('⚠️ Sign-in returned null (user cancelled?)');
      return false;
    } catch (error, stackTrace) {
      debugPrint('❌ Error signing in: $error');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _isSignedIn = false;
      
      // Clear sign in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_signed_in', false);
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error signing out: $error');
    }
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    if (_currentUser == null) return null;
    
    try {
      final auth = await _currentUser!.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }
}
