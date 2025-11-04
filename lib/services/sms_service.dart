import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

/// Service for managing SMS operations on Android
/// Note: iOS doesn't allow programmatic SMS sending/reading via third-party apps
class SmsService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.epansa.app/sms');
  
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isRequestingPermission = false;

  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  bool get isSupported => Platform.isAndroid;

  /// Initialize the SMS service (Android only)
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Initializing SMS service...');

    if (!Platform.isAndroid) {
      debugPrint('⚠SMS service is only supported on Android');
      _isInitialized = true;
      return;
    }

    try {
      // Check SMS permission status
      final smsStatus = await Permission.sms.status;
      _hasPermission = smsStatus.isGranted;
      debugPrint('Initial SMS permission status: $smsStatus');

      _isInitialized = true;
      debugPrint('SMS service initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize SMS service: $e');
      _isInitialized = true;
    }
  }

  /// Check and request SMS permissions (Android only)
  Future<void> _checkSmsPermissions() async {
    if (!Platform.isAndroid) {
      debugPrint('⚠SMS permissions not available on iOS');
      return;
    }

    if (_isRequestingPermission) {
      debugPrint('Permission request already in progress, skipping...');
      return;
    }

    try {
      _isRequestingPermission = true;
      debugPrint('Checking SMS permissions...');

      final smsStatus = await Permission.sms.status;
      debugPrint('SMS permission status: $smsStatus');

      if (!smsStatus.isGranted) {
        debugPrint('Requesting SMS permission...');
        
        final result = await Permission.sms.request();
        _hasPermission = result.isGranted;
        
        debugPrint('Permission after request: $_hasPermission');
        
        if (result.isPermanentlyDenied) {
          debugPrint('⚠SMS permission permanently denied, opening settings...');
          await openAppSettings();
        } else if (!_hasPermission) {
          debugPrint('⚠SMS permission denied');
        } else {
          debugPrint('SMS permission granted');
        }
      } else {
        _hasPermission = true;
        debugPrint('SMS permission already granted');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error checking/requesting SMS permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      _hasPermission = false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission() async {
    if (!Platform.isAndroid) {
      debugPrint('⚠SMS not supported on iOS');
      return false;
    }

    try {
      final status = await Permission.sms.status;
      _hasPermission = status.isGranted;
      debugPrint('Current SMS permission status: $status');
      return _hasPermission;
    } catch (e) {
      debugPrint('Error checking SMS permission: $e');
      return false;
    }
  }

  /// Send an SMS message
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      debugPrint('🚀 ===== SEND SMS CALLED ===== ');
      debugPrint('Phone number: $phoneNumber');
      debugPrint('Message: $message');

      if (!Platform.isAndroid) {
        debugPrint('SMS sending not supported on iOS');
        return false;
      }

      // Check permission
      final hasPerm = await hasSmsPermission();
      debugPrint('Has SMS permission: $hasPerm');

      if (!hasPerm) {
        debugPrint('⚠No SMS permission, requesting...');
        await _checkSmsPermissions();
        
        final hasPermAfterRequest = await hasSmsPermission();
        if (!hasPermAfterRequest) {
          debugPrint('SMS permission denied');
          return false;
        }
      }

      debugPrint('Sending SMS to $phoneNumber...');

      try {
        final bool result = await _channel.invokeMethod('sendSms', {
          'phoneNumber': phoneNumber,
          'message': message,
        });

        if (result) {
          debugPrint('SMS sent successfully');
          notifyListeners();
          return true;
        } else {
          debugPrint('Failed to send SMS');
          return false;
        }
      } catch (e, stackTrace) {
        debugPrint('Exception while sending SMS: $e');
        debugPrint('Stack trace: $stackTrace');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error in sendSms: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Read SMS messages (requires READ_SMS permission on Android)
  Future<List<SmsMessage>> readSms({
    int? limit,
    String? phoneNumber,
  }) async {
    try {
      debugPrint('Reading SMS messages...');

      if (!Platform.isAndroid) {
        debugPrint('SMS reading not supported on iOS');
        return [];
      }

      // Check if we need read SMS permission
      final readSmsStatus = await Permission.sms.status;
      if (!readSmsStatus.isGranted) {
        debugPrint('⚠No SMS read permission');
        await _checkSmsPermissions();
        
        final hasPermAfterRequest = await Permission.sms.status;
        if (!hasPermAfterRequest.isGranted) {
          debugPrint('SMS read permission denied');
          return [];
        }
      }

      try {
        final List<dynamic>? result = await _channel.invokeMethod('readSms', {
          'limit': limit ?? 10,
          'phoneNumber': phoneNumber,
        });

        if (result == null) {
          debugPrint('⚠No SMS messages found');
          return [];
        }

        final messages = result.map((msg) => SmsMessage.fromMap(msg)).toList();
        debugPrint('Retrieved ${messages.length} SMS messages');
        return messages;
      } catch (e, stackTrace) {
        debugPrint('Exception while reading SMS: $e');
        debugPrint('Stack trace: $stackTrace');
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error in readSms: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}

/// Represents an SMS message
class SmsMessage {
  final String id;
  final String address;
  final String body;
  final DateTime date;
  final bool isRead;
  final SmsType type;

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.isRead,
    required this.type,
  });

  factory SmsMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessage(
      id: map['id']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int? ?? 0),
      isRead: map['isRead'] as bool? ?? false,
      type: SmsType.values[map['type'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type.index,
    };
  }
}

/// SMS message type
enum SmsType {
  inbox,
  sent,
  draft,
  outbox,
  failed,
  queued,
}
