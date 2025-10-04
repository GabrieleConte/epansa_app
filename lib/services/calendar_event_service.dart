import 'package:flutter/foundation.dart';
import 'package:manage_calendar_events/manage_calendar_events.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing calendar events using manage_calendar_events package
/// This service provides calendar integration that works across iOS and Android
class CalendarEventService extends ChangeNotifier {
  final CalendarPlugin _calendarPlugin = CalendarPlugin();
  String? _defaultCalendarId;
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isRequestingPermission = false;

  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;

  /// Initialize the calendar service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('📅 Initializing calendar event service...');

    try {
      // Just check status without requesting on initialization
      final status = await Permission.calendarFullAccess.status;
      _hasPermission = status.isGranted;
      debugPrint('📊 Initial calendar permission status: $status');

      // Try to get default calendar if we have permission
      if (_hasPermission) {
        try {
          final calendars = await _calendarPlugin.getCalendars();
          if (calendars != null && calendars.isNotEmpty) {
            // Find first writable calendar
            debugPrint('📅 Found ${calendars.length} calendars:');
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
            debugPrint('📅 Default calendar: ${writableCalendar.name}');
            debugPrint('   ID: $_defaultCalendarId');
            debugPrint('   isReadOnly: ${writableCalendar.isReadOnly}');
          }
        } catch (e) {
          debugPrint('⚠️ Could not retrieve calendars: $e');
        }
      }

      _isInitialized = true;
      debugPrint('✅ Calendar event service initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to initialize calendar service: $e');
      _isInitialized = true;
    }
  }

  /// Check and request calendar permissions
  Future<void> _checkCalendarPermissions() async {
    if (_isRequestingPermission) {
      debugPrint('⏳ Permission request already in progress, skipping...');
      return;
    }

    try {
      _isRequestingPermission = true;
      debugPrint('📱 Checking calendar permissions...');

      final hasPermission = await _calendarPlugin.hasPermissions();
      debugPrint('📊 manage_calendar_events hasPermissions: $hasPermission');

      if (hasPermission != true) {
        debugPrint('🔐 Requesting calendar permissions...');
        await _calendarPlugin.requestPermissions();
        await Future.delayed(const Duration(milliseconds: 500));
        
        final grantedAfterRequest = await _calendarPlugin.hasPermissions();
        _hasPermission = grantedAfterRequest == true;
        
        debugPrint('📊 Permission after request: $_hasPermission');
        
        if (!_hasPermission) {
          debugPrint('⚠️ Calendar permission denied');
          await openAppSettings();
        } else {
          debugPrint('✅ Calendar permission granted');
        }
      } else {
        _hasPermission = true;
        debugPrint('✅ Calendar permission already granted');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking/requesting calendar permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      _hasPermission = false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  /// Check if calendar permission is granted
  Future<bool> hasCalendarPermission() async {
    try {
      final status = await Permission.calendarFullAccess.status;
      final hasPermViaPlugin = await _calendarPlugin.hasPermissions();
      _hasPermission = status.isGranted || (hasPermViaPlugin == true);
      debugPrint('📊 Current calendar permission status:');
      debugPrint('   - permission_handler: $status');
      debugPrint('   - manage_calendar_events: $hasPermViaPlugin');
      return _hasPermission;
    } catch (e) {
      debugPrint('❌ Error checking calendar permission: $e');
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
      debugPrint('🚀 ===== CREATE EVENT CALLED ===== 🚀');
      debugPrint('📅 Event title: $title');
      debugPrint('📅 Event start: $startTime');

      // Check permission
      final hasPerm = await hasCalendarPermission();
      debugPrint('📊 Has calendar permission: $hasPerm');

      if (!hasPerm) {
        debugPrint('⚠️ No calendar permission, requesting...');
        await _checkCalendarPermissions();
        
        final hasPermAfterRequest = await hasCalendarPermission();
        if (!hasPermAfterRequest) {
          debugPrint('❌ Calendar permission denied');
          return null;
        }
      }

      // Get or refresh calendar ID - look for writable calendar
      String? calendarId = _defaultCalendarId;
      if (calendarId == null) {
        debugPrint('📅 Getting available calendars...');
        final calendars = await _calendarPlugin.getCalendars();
        if (calendars == null || calendars.isEmpty) {
          debugPrint('❌ No calendars available');
          return null;
        }
        
        // Log all calendars
        debugPrint('📅 Found ${calendars.length} calendars:');
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
        debugPrint('📅 Using calendar: ${writableCalendar.name}');
        debugPrint('   ID: $calendarId');
        debugPrint('   isReadOnly: ${writableCalendar.isReadOnly}');
      }

      debugPrint('📅 Creating calendar event: $title');
      debugPrint('   Calendar ID: $calendarId');
      debugPrint('   Start: $startTime');
      debugPrint('   End: $endTime');
      debugPrint('   Description: $description');
      debugPrint('   Location: $location');

      try {
        final CalendarEvent event = CalendarEvent(
          title: title,
          description: description,
          startDate: startTime,
          endDate: endTime,
          location: location,
        );

        debugPrint('📅 CalendarEvent object created, calling plugin.createEvent...');
        
        final result = await _calendarPlugin.createEvent(
          calendarId: calendarId!,
          event: event,
        );

        debugPrint('📅 Plugin.createEvent returned: $result');

        if (result == null || result.isEmpty) {
          debugPrint('❌ Failed to create calendar event - result was null or empty');
          debugPrint('   Result value: $result');
          return null;
        }

        debugPrint('✅ Calendar event created successfully');
        debugPrint('   Event ID: $result');
        notifyListeners();
        return result;
      } catch (e, stackTrace) {
        debugPrint('❌ Exception while creating calendar event: $e');
        debugPrint('Stack trace: $stackTrace');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in createEvent: $e');
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
          debugPrint('❌ No calendar permission');
          return false;
        }
      }

      String? calendarId = _defaultCalendarId;
      if (calendarId == null) {
        final calendars = await _calendarPlugin.getCalendars();
        if (calendars == null || calendars.isEmpty) {
          debugPrint('❌ No calendars available');
          return false;
        }
        calendarId = calendars.first.id;
      }

      debugPrint('📅 Deleting calendar event: $eventId');

      final result = await _calendarPlugin.deleteEvent(
        calendarId: calendarId!,
        eventId: eventId,
      );

      if (result == true) {
        debugPrint('✅ Calendar event deleted successfully');
        notifyListeners();
        return true;
      }

      debugPrint('❌ Failed to delete calendar event');
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting calendar event: $e');
      return false;
    }
  }
}
