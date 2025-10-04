import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Model for an alarm
class Alarm {
  final String id;
  final String label;
  final TimeOfDay time;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday, empty = one-time
  final bool isEnabled;
  final DateTime? nextTrigger;

  Alarm({
    required this.id,
    required this.label,
    required this.time,
    this.repeatDays = const [],
    this.isEnabled = true,
    this.nextTrigger,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': time.hour,
        'minute': time.minute,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'nextTrigger': nextTrigger?.toIso8601String(),
      };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
        id: json['id'] as String,
        label: json['label'] as String,
        time: TimeOfDay(
          hour: json['hour'] as int,
          minute: json['minute'] as int,
        ),
        repeatDays: (json['repeatDays'] as List<dynamic>?)?.cast<int>() ?? [],
        isEnabled: json['isEnabled'] as bool? ?? true,
        nextTrigger: json['nextTrigger'] != null
            ? DateTime.parse(json['nextTrigger'] as String)
            : null,
      );

  String getRepeatText() {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => dayNames[d - 1]).join(', ');
  }

  String getTimeText() {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Service for managing device alarms
class AlarmService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<Alarm> _alarms = [];
  bool _isInitialized = false;

  List<Alarm> get alarms => _alarms;
  bool get isInitialized => _isInitialized;

  /// Initialize the alarm service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔔 Initializing alarm service...');

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Initialize notifications
    await _initializeNotifications();

    // Load saved alarms (you can use SharedPreferences or local DB)
    await _loadAlarms();

    _isInitialized = true;
    debugPrint('✅ Alarm service initialized');
  }

  /// Initialize local notifications
  Future<void> _initializeNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        debugPrint('iOS notification received: $title');
      },
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Request permissions
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
          
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  /// Load alarms from storage
  Future<void> _loadAlarms() async {
    // TODO: Load from SharedPreferences or local database
    // For now, start with empty list
    _alarms = [];
  }

  /// Save alarms to storage
  Future<void> _saveAlarms() async {
    // TODO: Save to SharedPreferences or local database
    debugPrint('💾 Saving ${_alarms.length} alarms');
  }

  /// Create a new alarm
  Future<bool> createAlarm({
    required String label,
    required TimeOfDay time,
    List<int> repeatDays = const [],
  }) async {
    try {
      final alarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: label,
        time: time,
        repeatDays: repeatDays,
        isEnabled: true,
      );

      await _scheduleAlarm(alarm);

      _alarms.add(alarm);
      await _saveAlarms();
      notifyListeners();

      debugPrint('✅ Alarm created: ${alarm.label} at ${alarm.getTimeText()}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to create alarm: $e');
      return false;
    }
  }

  /// Schedule an alarm notification
  Future<void> _scheduleAlarm(Alarm alarm) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If the alarm time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Notification details
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    if (alarm.repeatDays.isEmpty) {
      // One-time alarm
      await _notifications.zonedSchedule(
        int.parse(alarm.id),
        '⏰ ${alarm.label}',
        'Alarm',
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('📅 Scheduled one-time alarm for ${tzScheduledDate}');
    } else {
      // Repeating alarm - schedule for each day
      for (final day in alarm.repeatDays) {
        final dayOfWeek = day % 7; // Convert 1-7 to 0-6
        await _scheduleRepeatingAlarm(alarm, dayOfWeek, details);
      }
      debugPrint('🔁 Scheduled repeating alarm for ${alarm.repeatDays.length} days');
    }
  }

  /// Schedule a repeating alarm for a specific day of week
  Future<void> _scheduleRepeatingAlarm(
    Alarm alarm,
    int dayOfWeek,
    NotificationDetails details,
  ) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // Find next occurrence of this day
    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Create unique ID for each day
    final notificationId = int.parse(alarm.id) + dayOfWeek;

    await _notifications.zonedSchedule(
      notificationId,
      '⏰ ${alarm.label}',
      'Alarm',
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Delete an alarm
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      // Cancel notification
      await _notifications.cancel(int.parse(alarmId));

      // Cancel all day-specific notifications for repeating alarms
      for (int i = 0; i < 7; i++) {
        await _notifications.cancel(int.parse(alarmId) + i);
      }

      _alarms.removeWhere((a) => a.id == alarmId);
      await _saveAlarms();
      notifyListeners();

      debugPrint('✅ Alarm deleted: $alarmId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete alarm: $e');
      return false;
    }
  }

  /// Toggle alarm enabled/disabled
  Future<bool> toggleAlarm(String alarmId) async {
    try {
      final index = _alarms.indexWhere((a) => a.id == alarmId);
      if (index == -1) return false;

      final alarm = _alarms[index];
      final newAlarm = Alarm(
        id: alarm.id,
        label: alarm.label,
        time: alarm.time,
        repeatDays: alarm.repeatDays,
        isEnabled: !alarm.isEnabled,
      );

      if (newAlarm.isEnabled) {
        await _scheduleAlarm(newAlarm);
      } else {
        await _notifications.cancel(int.parse(alarm.id));
        for (int i = 0; i < 7; i++) {
          await _notifications.cancel(int.parse(alarm.id) + i);
        }
      }

      _alarms[index] = newAlarm;
      await _saveAlarms();
      notifyListeners();

      debugPrint('✅ Alarm toggled: ${newAlarm.label} - ${newAlarm.isEnabled}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to toggle alarm: $e');
      return false;
    }
  }

  /// Get all alarms for syncing
  Future<List<Map<String, dynamic>>> getAllAlarmsForSync() async {
    return _alarms.map((a) => a.toJson()).toList();
  }

  /// Fetch alarms from device (returns current managed alarms)
  Future<List<Map<String, dynamic>>> fetchDeviceAlarms() async {
    debugPrint('📱 Fetching ${_alarms.length} alarms from alarm service');
    return getAllAlarmsForSync();
  }
}
