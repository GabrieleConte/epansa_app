import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service for managing device alarms
/// - Android: Uses flutter_alarm_clock to open system Clock app
/// - iOS: Uses local notifications as alarms (iOS doesn't support programmatic alarms)
class AlarmService extends ChangeNotifier {
  bool _isInitialized = false;
  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  int _notificationId = 0;

  bool get isInitialized => _isInitialized;

  /// Initialize the alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔔 Initializing alarm service...');

    try {
      // Initialize timezone data for scheduled notifications
      tz.initializeTimeZones();
      
      if (Platform.isAndroid) {
        debugPrint('📱 Android: Using flutter_alarm_clock');
        await _checkAndroidPermissions();
      } else if (Platform.isIOS) {
        debugPrint('🍎 iOS: Using local notifications for alarms');
        await _initializeNotifications();
      }

      _isInitialized = true;
      debugPrint('✅ Alarm service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize alarm service: $e');
    }
  }

  /// Initialize local notifications for iOS
  Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin!.initialize(initializationSettings);
    
    // Request iOS notification permissions
    if (Platform.isIOS) {
      await _notificationsPlugin!
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }



  /// Check and request Android permissions
  Future<void> _checkAndroidPermissions() async {
    try {
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

  /// Create a new alarm
  /// - Android: Creates alarm silently without opening Clock app (skipUi: true)
  /// - iOS: Creates a local notification scheduled for the specified time
  /// Returns true if successful, false otherwise
  Future<bool> createAlarm({
    required String label,
    required TimeOfDay time,
    List<int> repeatDays = const [],
    bool skipUi = true, // Default to true to avoid opening Clock app
  }) async {
    try {
      debugPrint('🔔 Creating alarm: $label at ${time.hour}:${time.minute}');

      if (Platform.isAndroid) {
        // Android: Use flutter_alarm_clock to open system Clock app
        FlutterAlarmClock.createAlarm(
          hour: time.hour,
          minutes: time.minute,
          title: label,
          skipUi: skipUi,
        );
        debugPrint('✅ Android alarm created - Clock app will open');
        return true;
      } else if (Platform.isIOS) {
        // iOS: Create scheduled notification
        return await _createIOSNotificationAlarm(
          label: label,
          time: time,
          repeatDays: repeatDays,
        );
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to create alarm: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Create an iOS notification alarm
  Future<bool> _createIOSNotificationAlarm({
    required String label,
    required TimeOfDay time,
    List<int> repeatDays = const [],
  }) async {
    try {
      if (_notificationsPlugin == null) {
        debugPrint('❌ Notifications not initialized');
        return false;
      }

      // Generate unique notification ID
      final notificationId = _notificationId++;

      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'alarm_channel',
        'Alarms',
        channelDescription: 'Alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarm_sound'),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'alarm_sound.aiff',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Calculate scheduled time
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Schedule notification
      await _notificationsPlugin!.zonedSchedule(
        notificationId,
        'Alarm',
        label,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ iOS notification alarm scheduled for ${scheduledDate.toString()}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to create iOS notification alarm: $e');
      return false;
    }
  }

  /// Show all alarms in the system Clock app
  /// Opens the native alarm list screen
  Future<void> showAlarms() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('❌ Show alarms only supported on Android');
        return;
      }

      debugPrint('📱 Opening system alarms...');
      FlutterAlarmClock.showAlarms();
      debugPrint('✅ System alarms screen opened');
    } catch (e) {
      debugPrint('❌ Failed to show alarms: $e');
    }
  }

  /// Create a timer (countdown)
  /// Opens the system timer with specified duration
  Future<void> createTimer({
    required int seconds,
    String? title,
    bool skipUi = false,
  }) async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('❌ Timer creation only supported on Android');
        return;
      }

      debugPrint('⏱️ Creating timer: $seconds seconds');
      
      FlutterAlarmClock.createTimer(
        length: seconds,
        title: title ?? 'Timer',
        skipUi: skipUi,
      );

      debugPrint('✅ Timer created successfully');
    } catch (e) {
      debugPrint('❌ Failed to create timer: $e');
    }
  }

  /// Show all timers in the system Clock app
  Future<void> showTimers() async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('❌ Show timers only supported on Android');
        return;
      }

      debugPrint('📱 Opening system timers...');
      FlutterAlarmClock.showTimers();
      debugPrint('✅ System timers screen opened');
    } catch (e) {
      debugPrint('❌ Failed to show timers: $e');
    }
  }

  /// Check if notification permissions are granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if schedule exact alarm permission is granted (Android 12+)
  Future<bool> hasScheduleExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ Error checking schedule exact alarm permission: $e');
      return false;
    }
  }

  /// Get all alarms for syncing
  /// Note: flutter_alarm_clock doesn't provide a way to read existing alarms
  /// This method returns an empty list as we can't access system alarms
  Future<List<Map<String, dynamic>>> getAllAlarmsForSync() async {
    debugPrint('⚠️ flutter_alarm_clock cannot read existing system alarms');
    debugPrint('💡 Only alarm creation is supported, not reading');
    return [];
  }

  /// Fetch alarms from device
  /// Note: Not possible with flutter_alarm_clock package
  Future<List<Map<String, dynamic>>> fetchDeviceAlarms() async {
    debugPrint('⚠️ Cannot fetch device alarms with flutter_alarm_clock');
    debugPrint('💡 This package only supports creating alarms, not reading them');
    return [];
  }

  @override
  void dispose() {
    super.dispose();
  }
}
