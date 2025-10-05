import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Service for making phone calls
/// Note: iOS can initiate calls but permission handling is different from Android
class CallService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isRequestingPermission = false;

  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Initialize the call service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('📞 Initializing call service...');

    try {
      if (Platform.isAndroid) {
        // Check phone permission status on Android
        final phoneStatus = await Permission.phone.status;
        _hasPermission = phoneStatus.isGranted;
        debugPrint('📊 Initial phone permission status: $phoneStatus');
      } else if (Platform.isIOS) {
        // iOS doesn't require explicit permission for tel: URLs
        // The system will handle the call confirmation
        _hasPermission = true;
        debugPrint('📊 iOS: Phone calls handled by system');
      } else {
        debugPrint('⚠️ Call service not supported on this platform');
      }

      _isInitialized = true;
      debugPrint('✅ Call service initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize call service: $e');
      _isInitialized = true;
    }
  }

  /// Check and request phone permissions (Android only)
  Future<void> _checkPhonePermissions() async {
    if (!Platform.isAndroid) {
      // iOS doesn't need explicit permission
      _hasPermission = true;
      return;
    }

    if (_isRequestingPermission) {
      debugPrint('⏳ Permission request already in progress, skipping...');
      return;
    }

    try {
      _isRequestingPermission = true;
      debugPrint('📱 Checking phone permissions...');

      final phoneStatus = await Permission.phone.status;
      debugPrint('📊 Phone permission status: $phoneStatus');

      if (!phoneStatus.isGranted) {
        debugPrint('🔐 Requesting phone permission...');
        
        final result = await Permission.phone.request();
        _hasPermission = result.isGranted;
        
        debugPrint('📊 Permission after request: $_hasPermission');
        
        if (result.isPermanentlyDenied) {
          debugPrint('⚠️ Phone permission permanently denied, opening settings...');
          await openAppSettings();
        } else if (!_hasPermission) {
          debugPrint('⚠️ Phone permission denied');
        } else {
          debugPrint('✅ Phone permission granted');
        }
      } else {
        _hasPermission = true;
        debugPrint('✅ Phone permission already granted');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking/requesting phone permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      _hasPermission = false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  /// Check if phone permission is granted
  Future<bool> hasPhonePermission() async {
    if (Platform.isIOS) {
      // iOS doesn't require explicit permission
      debugPrint('📊 iOS: Phone calls allowed by system');
      return true;
    }

    if (!Platform.isAndroid) {
      debugPrint('⚠️ Phone calls not supported on this platform');
      return false;
    }

    try {
      final status = await Permission.phone.status;
      _hasPermission = status.isGranted;
      debugPrint('📊 Current phone permission status: $status');
      return _hasPermission;
    } catch (e) {
      debugPrint('❌ Error checking phone permission: $e');
      return false;
    }
  }

  /// Make a phone call
  Future<bool> makeCall({
    required String phoneNumber,
  }) async {
    try {
      debugPrint('🚀 ===== MAKE CALL CALLED ===== 🚀');
      debugPrint('📞 Phone number: $phoneNumber');

      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('❌ Phone calls not supported on this platform');
        return false;
      }

      // Check permission (Android only)
      if (Platform.isAndroid) {
        final hasPerm = await hasPhonePermission();
        debugPrint('📊 Has phone permission: $hasPerm');

        if (!hasPerm) {
          debugPrint('⚠️ No phone permission, requesting...');
          await _checkPhonePermissions();
          
          final hasPermAfterRequest = await hasPhonePermission();
          if (!hasPermAfterRequest) {
            debugPrint('❌ Phone permission denied');
            return false;
          }
        }
      }

      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      debugPrint('📞 Making call to: $cleanNumber');

      try {
        final Uri telUri = Uri.parse('tel:$cleanNumber');
        
        // Check if the device can handle tel: URLs
        final bool canLaunch = await canLaunchUrl(telUri);
        
        if (!canLaunch) {
          debugPrint('❌ Device cannot handle tel: URLs');
          return false;
        }

        // Launch the phone dialer
        final bool launched = await launchUrl(telUri);

        if (launched) {
          debugPrint('✅ Phone call initiated successfully');
          notifyListeners();
          return true;
        } else {
          debugPrint('❌ Failed to launch phone dialer');
          return false;
        }
      } catch (e, stackTrace) {
        debugPrint('❌ Exception while making call: $e');
        debugPrint('Stack trace: $stackTrace');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in makeCall: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
