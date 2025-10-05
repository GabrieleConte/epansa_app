import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epansa_app/core/config/app_config.dart';
import 'dart:io' show Platform;

/// Authentication service for Google Sign-In
class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  AuthService() {
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

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      debugPrint('🔵 Attempting Google Sign-In...');
      debugPrint('🔵 Platform: ${kIsWeb ? "Web" : (Platform.isIOS ? "iOS" : "Android")}');
      
      // Use v6 signIn() method
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        debugPrint('❌ Sign-in cancelled by user');
        return false;
      }
      
      debugPrint('✅ Sign-in successful: ${account.email}');
      
      _currentUser = account;
      _isSignedIn = true;
      
      // Save sign in state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('was_signed_in', true);
      
      debugPrint('✅ Sign-in successful: ${account.email}');
      notifyListeners();
      return true;
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

  /// Get authentication tokens for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    if (_currentUser == null) {
      throw Exception('User not signed in');
    }

    try {
      // Get authentication object (v6 API)
      final auth = await _currentUser!.authentication;
      
      return {
        'Authorization': 'Bearer ${auth.accessToken}',
        'Content-Type': 'application/json',
      };
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      rethrow;
    }
  }
}
