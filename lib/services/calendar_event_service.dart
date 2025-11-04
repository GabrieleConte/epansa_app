import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for managing calendar events using device_calendar package
/// This service provides calendar integration that works across iOS and Android
class CalendarEventService extends ChangeNotifier {
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();
  String? _defaultCalendarId;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isRequestingPermission = false;

  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;

  /// Initialize the calendar service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Initializing calendar event service...');

    try {
      // Check permissions using device_calendar
      var permissionsGranted = await _calendarPlugin.hasPermissions();
      _hasPermission = permissionsGranted.isSuccess && (permissionsGranted.data ?? false);
      debugPrint('Initial calendar permission status: $_hasPermission');

      // Try to get default calendar if we have permission
      if (_hasPermission) {
        try {
          final calendarsResult = await _calendarPlugin.retrieveCalendars();
          if (calendarsResult.isSuccess && calendarsResult.data != null) {
            final calendars = calendarsResult.data!;
            // Find first writable calendar
            debugPrint('Found ${calendars.length} calendars:');
            for (var i = 0; i < calendars.length; i++) {
              final cal = calendars[i];
              debugPrint('   [$i] ${cal.name} (${cal.id})');
              debugPrint('       isReadOnly: ${cal.isReadOnly}');
              debugPrint('       accountName: ${cal.accountName}');
            }
            
            final writableCalendar = calendars.firstWhere(
              (cal) => !(cal.isReadOnly ?? true),
              orElse: () => calendars.first,
            );
            
            _defaultCalendarId = writableCalendar.id;
            debugPrint('Default calendar: ${writableCalendar.name}');
            debugPrint('   ID: $_defaultCalendarId');
            debugPrint('   isReadOnly: ${writableCalendar.isReadOnly}');
          }
        } catch (e) {
          debugPrint('⚠Could not retrieve calendars: $e');
        }
      }

      _isInitialized = true;
      debugPrint('Calendar event service initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize calendar service: $e');
      _isInitialized = true;
    }
  }

  /// Check and request calendar permissions
  Future<void> _checkCalendarPermissions() async {
    if (_isRequestingPermission) {
      debugPrint('Permission request already in progress, skipping...');
      return;
    }

    try {
      _isRequestingPermission = true;
      debugPrint('Checking calendar permissions...');

      final hasPermissionResult = await _calendarPlugin.hasPermissions();
      final hasPermission = hasPermissionResult.isSuccess && (hasPermissionResult.data ?? false);
      debugPrint('device_calendar hasPermissions: $hasPermission');

      if (!hasPermission) {
        debugPrint('Requesting calendar permissions...');
        final requestResult = await _calendarPlugin.requestPermissions();
        await Future.delayed(const Duration(milliseconds: 500));
        
        final grantedAfterRequest = requestResult.isSuccess && (requestResult.data ?? false);
        _hasPermission = grantedAfterRequest;
        
        debugPrint('Permission after request: $_hasPermission');
        
        if (!_hasPermission) {
          debugPrint('⚠Calendar permission denied');
          await openAppSettings();
        } else {
          debugPrint('Calendar permission granted');
        }
      } else {
        _hasPermission = true;
        debugPrint('Calendar permission already granted');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error checking/requesting calendar permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      _hasPermission = false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  /// Check if calendar permission is granted
  Future<bool> hasCalendarPermission() async {
    try {
      final hasPermResult = await _calendarPlugin.hasPermissions();
      _hasPermission = hasPermResult.isSuccess && (hasPermResult.data ?? false);
      debugPrint('Current calendar permission status: $_hasPermission');
      return _hasPermission;
    } catch (e) {
      debugPrint('Error checking calendar permission: $e');
      return false;
    }
  }

  /// Create a new calendar event
  Future<String?> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
    String? location,
  }) async {
    try {
      debugPrint('🚀 ===== CREATE EVENT CALLED ===== ');
      debugPrint('Event title: $title');
      debugPrint('Event start: $startTime');

      // Check permission
      final hasPerm = await hasCalendarPermission();
      debugPrint('Has calendar permission: $hasPerm');

      if (!hasPerm) {
        debugPrint('⚠No calendar permission, requesting...');
        await _checkCalendarPermissions();
        
        final hasPermAfterRequest = await hasCalendarPermission();
        if (!hasPermAfterRequest) {
          debugPrint('Calendar permission denied');
          return null;
        }
      }

      // Get or refresh calendar ID - look for writable calendar
      String? calendarId = _defaultCalendarId;
      if (calendarId == null) {
        debugPrint('Getting available calendars...');
        final calendarsResult = await _calendarPlugin.retrieveCalendars();
        if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
          debugPrint('No calendars available');
          return null;
        }
        
        final calendars = calendarsResult.data!;
        // Log all calendars
        debugPrint('Found ${calendars.length} calendars:');
        for (var i = 0; i < calendars.length; i++) {
          final cal = calendars[i];
          debugPrint('   [$i] ${cal.name} (${cal.id})');
          debugPrint('       isReadOnly: ${cal.isReadOnly}');
          debugPrint('       accountName: ${cal.accountName}');
        }
        
        // Find first writable calendar
        final writableCalendar = calendars.firstWhere(
          (cal) => !(cal.isReadOnly ?? true),
          orElse: () => calendars.first,
        );
        
        calendarId = writableCalendar.id;
        _defaultCalendarId = calendarId;
        debugPrint('Using calendar: ${writableCalendar.name}');
        debugPrint('   ID: $calendarId');
        debugPrint('   isReadOnly: ${writableCalendar.isReadOnly}');
      }

      debugPrint('Creating calendar event: $title');
      debugPrint('   Calendar ID: $calendarId');
      debugPrint('   Start: $startTime');
      debugPrint('   End: $endTime');
      debugPrint('   Description: $description');
      debugPrint('   Location: $location');

      try {
        // Convert DateTime to TZDateTime (use local timezone)
        final tzLocation = tz.local;
        final start = tz.TZDateTime.from(startTime, tzLocation);
        final end = tz.TZDateTime.from(endTime, tzLocation);
        
        final event = Event(
          calendarId,
          title: title,
          description: description,
          start: start,
          end: end,
          location: location,
        );

        debugPrint('Event object created, calling plugin.createOrUpdateEvent...');
        
        final result = await _calendarPlugin.createOrUpdateEvent(event);

        debugPrint('Plugin.createOrUpdateEvent returned: ${result?.isSuccess}');

        if (result == null || !result.isSuccess || result.data == null || result.data!.isEmpty) {
          debugPrint('Failed to create calendar event');
          if (result != null) {
            debugPrint('   Errors: ${result.errors}');
          }
          return null;
        }

        debugPrint('Calendar event created successfully');
        debugPrint('   Event ID: ${result.data}');
        notifyListeners();
        return result.data;
      } catch (e, stackTrace) {
        debugPrint('Exception while creating calendar event: $e');
        debugPrint('Stack trace: $stackTrace');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Error in createEvent: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Delete a calendar event
  Future<bool> deleteEvent({
    required String eventId,
  }) async {
    try {
      if (!_hasPermission) {
        await _checkCalendarPermissions();
        if (!_hasPermission) {
          debugPrint('No calendar permission');
          return false;
        }
      }

      String? calendarId = _defaultCalendarId;
      if (calendarId == null) {
        final calendarsResult = await _calendarPlugin.retrieveCalendars();
        if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
          debugPrint('No calendars available');
          return false;
        }
        calendarId = calendarsResult.data!.first.id;
      }

      debugPrint('Deleting calendar event: $eventId');

      final result = await _calendarPlugin.deleteEvent(calendarId, eventId);

      if (result.isSuccess && (result.data ?? false)) {
        debugPrint('Calendar event deleted successfully');
        notifyListeners();
        return true;
      }

      debugPrint('Failed to delete calendar event');
      debugPrint('   Errors: ${result.errors}');
      return false;
    } catch (e) {
      debugPrint('Error deleting calendar event: $e');
      return false;
    }
  }
}
