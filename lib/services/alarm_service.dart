import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing device alarms using the alarm package
/// This package provides proper alarm functionality that works even when app is terminated
class AlarmService extends ChangeNotifier {
  List<AlarmSettings> _alarms = [];
  bool _isInitialized = false;
  StreamSubscription<AlarmSettings>? _alarmSubscription;

  List<AlarmSettings> get alarms => _alarms;
  bool get isInitialized => _isInitialized;

  /// Initialize the alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔔 Initializing alarm service with alarm package...');

    try {
      // The alarm package is already initialized in main.dart with Alarm.init()
      // Here we just set up the service
      debugPrint('✅ Alarm package ready');

      // Request permissions based on platform
      if (Platform.isAndroid) {
        await _checkAndroidPermissions();
      } else if (Platform.isIOS) {
        await _checkIOSPermissions();
      }

      // Load existing alarms
      await _loadAlarms();

      // Listen to alarm ring events
      _alarmSubscription = Alarm.ringStream.stream.listen(_onAlarmRing);

      _isInitialized = true;
      debugPrint('✅ Alarm service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize alarm service: $e');
    }
  }

  /// Check and request iOS permissions
  Future<void> _checkIOSPermissions() async {
    try {
      debugPrint('📱 Checking iOS notification permissions...');
      
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      debugPrint('📊 iOS notification status: $notificationStatus');
      
      if (notificationStatus.isDenied || notificationStatus.isLimited) {
        debugPrint('📱 Requesting iOS notification permission...');
        final result = await Permission.notification.request();
        debugPrint('📊 iOS notification permission result: $result');
        
        if (result.isPermanentlyDenied) {
          debugPrint('⚠️ Notification permission permanently denied. User needs to enable in Settings.');
          debugPrint('💡 Go to: Settings > EPANSA > Notifications');
        }
      } else if (notificationStatus.isGranted) {
        debugPrint('✅ iOS notification permission already granted');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking iOS permissions: $e');
    }
  }

  /// Check and request Android permissions
  Future<void> _checkAndroidPermissions() async {
    try {
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      if (notificationStatus.isDenied) {
        debugPrint('📱 Requesting notification permission...');
        await Permission.notification.request();
      }

      // Check schedule exact alarm permission (Android 12+)
      final scheduleAlarmStatus = await Permission.scheduleExactAlarm.status;
      debugPrint('📅 Schedule exact alarm permission: $scheduleAlarmStatus');
      if (scheduleAlarmStatus.isDenied) {
        debugPrint('📱 Requesting schedule exact alarm permission...');
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('⚠️ Error checking Android permissions: $e');
    }
  }

  /// Load existing alarms
  Future<void> _loadAlarms() async {
    _alarms = await Alarm.getAlarms();
    _alarms.sort((a, b) => a.dateTime.isBefore(b.dateTime) ? 0 : 1);
    debugPrint('📋 Loaded ${_alarms.length} existing alarms');
    notifyListeners();
  }

  /// Handle alarm ring event
  void _onAlarmRing(AlarmSettings alarmSettings) async {
    debugPrint('🔔 Alarm ringing: ${alarmSettings.notificationSettings.title}');
    // You can add custom behavior here, like navigating to a screen
    // For now, we just reload the alarms
    await _loadAlarms();
  }

  /// Create a new alarm
  /// Returns true if successful, false otherwise
  Future<bool> createAlarm({
    required String label,
    required TimeOfDay time,
    List<int> repeatDays = const [],
    bool testMode = false, // For testing: set alarm in 10 seconds
  }) async {
    try {
      final now = DateTime.now();
      DateTime alarmDateTime;

      if (testMode) {
        // TEST MODE: Set alarm for 10 seconds from now
        alarmDateTime = now.add(const Duration(seconds: 10));
        debugPrint('⚠️ TEST MODE: Alarm will fire in 10 seconds at $alarmDateTime');
      } else {
        // Calculate alarm time
        alarmDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If the alarm time has passed today, schedule for tomorrow
        if (alarmDateTime.isBefore(now)) {
          alarmDateTime = alarmDateTime.add(const Duration(days: 1));
        }
      }

      // Generate unique ID
      final id = alarmDateTime.millisecondsSinceEpoch % 2147483647; // Keep within 32-bit int range

      // Create alarm settings with test mode enabled (fires in 10 seconds)
      final alarmSettings = AlarmSettings(
        id: id,
        dateTime: alarmDateTime,
        assetAudioPath: 'assets/alarm.mp3', // TODO: Add proper audio file
        loopAudio: true,
        vibrate: true,
        volumeSettings: VolumeSettings.fade(
          volume: 0.8,
          fadeDuration: const Duration(seconds: 3),
        ),
        notificationSettings: NotificationSettings(
          title: testMode ? '⏰ EPANSA Test Alarm' : '⏰ $label',
          body: testMode 
              ? '🔔 Tap notification or swipe to stop' 
              : 'Alarm ringing - Tap to stop',
          stopButton: Platform.isIOS ? 'Stop Alarm' : 'Stop',
        ),
        warningNotificationOnKill: Platform.isIOS,
        androidFullScreenIntent: true, // Show full screen on Android
      );

      // Set the alarm
      await Alarm.set(alarmSettings: alarmSettings);

      // Reload alarms
      await _loadAlarms();

      debugPrint('✅ Alarm created: $label at ${alarmDateTime.toString()} (ID: $id)');
      debugPrint('📱 Total alarms scheduled: ${_alarms.length}');
      if (Platform.isIOS) {
        debugPrint('⚠️ Note: iOS alarms are notifications, not native Clock alarms');
        debugPrint('💡 The notification will fire at the scheduled time if permissions are granted');
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to create alarm: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Stop an alarm
  Future<bool> stopAlarm(int id) async {
    try {
      await Alarm.stop(id);
      await _loadAlarms();
      debugPrint('✅ Alarm stopped: $id');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to stop alarm: $e');
      return false;
    }
  }

  /// Stop all alarms
  Future<void> stopAll() async {
    try {
      await Alarm.stopAll();
      await _loadAlarms();
      debugPrint('✅ All alarms stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop all alarms: $e');
    }
  }

  /// Check if any alarm is currently ringing
  Future<bool> isRinging() async {
    return Alarm.hasAlarm();
  }

  /// Check if notification permissions are granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Get all alarms for syncing
  Future<List<Map<String, dynamic>>> getAllAlarmsForSync() async {
    return _alarms.map((a) => {
      'id': a.id,
      'label': a.notificationSettings.title,
      'time': a.dateTime.toIso8601String(),
    }).toList();
  }

  /// Fetch alarms from device (returns current managed alarms)
  Future<List<Map<String, dynamic>>> fetchDeviceAlarms() async {
    debugPrint('📱 Fetching ${_alarms.length} alarms from alarm service');
    return getAllAlarmsForSync();
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }
}
