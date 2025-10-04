import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

// Background task identifier
const String syncTaskName = "epansa-background-sync";
const String syncTaskTag = "sync-task";

/// Background callback dispatcher - runs independently of the app
/// This function is called by the OS when it's time to sync
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background sync task triggered: $task');
    
    try {
      // Perform the background sync
      await _performBackgroundSyncTask();
      debugPrint('✅ Background sync task completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background sync task failed: $e');
      return Future.value(false);
    }
  });
}

/// Performs the actual sync work in the background
/// This is separate from the service class so it can run independently
Future<void> _performBackgroundSyncTask() async {
  debugPrint('📱 Executing background sync...');
  
  // Check if background sync is enabled
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('background_sync_enabled') ?? false;
  
  if (!isEnabled) {
    debugPrint('⚠️ Background sync is disabled, skipping');
    return;
  }
  
  // Perform mock sync operations
  await _backgroundSyncNotes();
  await _backgroundSyncContacts();
  // Calendar reading removed - handled by server reading Google Calendar
  await _backgroundSyncAlarms();
  await _backgroundSyncCallRegistry();
  
  // Update last sync time
  await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
  debugPrint('✅ Background sync completed');
}

Future<void> _backgroundSyncNotes() async {
  debugPrint('📝 [Background] Syncing notes...');
  await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('✅ [Background] Notes synced');
}

Future<void> _backgroundSyncContacts() async {
  debugPrint('👥 [Background] Syncing contacts...');
  await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('✅ [Background] Contacts synced');
}

// Calendar reading removed - server handles Google Calendar
// App will only write events to device calendar when received from server

Future<void> _backgroundSyncAlarms() async {
  debugPrint('⏰ [Background] Syncing alarms...');
  await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('✅ [Background] Alarms synced');
}

Future<void> _backgroundSyncCallRegistry() async {
  debugPrint('📞 [Background] Syncing call registry...');
  await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('✅ [Background] Call registry synced');
}

/// Service for syncing user data (notes, contacts, calendar) with the agent server
class SyncService extends ChangeNotifier {
  bool _isBackgroundSyncEnabled = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isBackgroundSyncEnabled => _isBackgroundSyncEnabled;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService() {
    _loadSyncPreferences();
  }

  /// Load sync preferences from storage
  Future<void> _loadSyncPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isBackgroundSyncEnabled = prefs.getBool('background_sync_enabled') ?? false;
    final lastSyncTimestamp = prefs.getInt('last_sync_time');
    if (lastSyncTimestamp != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
    }
    notifyListeners();
  }

  /// Enable background sync
  Future<void> enableBackgroundSync() async {
    debugPrint('📱 Enabling background sync...');
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_sync_enabled', true);
    
    _isBackgroundSyncEnabled = true;
    notifyListeners();

    // Register periodic background task
    try {
      if (kIsWeb) {
        debugPrint('⚠️ Background sync not supported on web platform');
      } else if (Platform.isIOS) {
        // iOS doesn't support periodic background tasks like Android
        // iOS will only sync when app is opened or in foreground
        debugPrint('⚠️ Background sync not supported on iOS');
        debugPrint('💡 Data will sync automatically when you open the app');
      } else {
        // Android: Register periodic task (every 15 minutes minimum)
        await Workmanager().registerPeriodicTask(
          syncTaskName,
          syncTaskTag,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected, // Only sync when connected to internet
            requiresBatteryNotLow: true, // Don't sync if battery is low
          ),
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        debugPrint('✅ Background task registered successfully');
      }
    } catch (e) {
      debugPrint('❌ Failed to register background task: $e');
    }

    // Perform initial sync
    await performSync();

    debugPrint('✅ Background sync enabled');
  }

  /// Disable background sync
  Future<void> disableBackgroundSync() async {
    debugPrint('📱 Disabling background sync...');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_sync_enabled', false);
    
    _isBackgroundSyncEnabled = false;
    notifyListeners();

    // Cancel background task
    try {
      if (!kIsWeb) {
        await Workmanager().cancelByUniqueName(syncTaskName);
        debugPrint('✅ Background task cancelled');
      }
    } catch (e) {
      debugPrint('❌ Failed to cancel background task: $e');
    }

    debugPrint('✅ Background sync disabled');
  }

  /// Perform manual sync
  Future<bool> performSync() async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync already in progress');
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    debugPrint('🔄 Starting data sync...');

    try {
      // Mock sync operations (replace with real API calls)
      await _syncNotes();
      await _syncContacts();
      // Calendar reading removed - server handles Google Calendar
      await _syncAlarms();
      await _syncCallRegistry();

      // Update last sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_sync_time', _lastSyncTime!.millisecondsSinceEpoch);

      debugPrint('✅ Sync completed successfully');
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Sync failed: $e');
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Sync notes with server (mock implementation)
  Future<void> _syncNotes() async {
    debugPrint('📝 Syncing notes...');
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    // In real implementation, call the agent server:
    // final response = await http.post(
    //   Uri.parse('${AppConfig.agentApiBaseUrl}/sync/notes'),
    //   headers: {
    //     'Authorization': 'Bearer ${AppConfig.agentApiKey}',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({
    //     'notes': await _fetchLocalNotes(),
    //   }),
    // );

    debugPrint('✅ Notes synced');
  }

  /// Sync contacts with server
  Future<void> _syncContacts() async {
    debugPrint('👥 Syncing contacts...');
    
    // Fetch real device contacts
    final contactsData = await _fetchDeviceContacts();
    debugPrint('📱 Fetched ${contactsData.length} contacts from device');
    
    // TODO: Send to remote agent server once API is ready
    // final response = await http.post(
    //   Uri.parse('${AppConfig.agentApiBaseUrl}/sync/contacts'),
    //   headers: {
    //     'Authorization': 'Bearer ${AppConfig.agentApiKey}',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({'contacts': contactsData}),
    // );

    debugPrint('✅ Contacts synced (${contactsData.length} contacts)');
  }

  // Calendar reading removed - server handles Google Calendar via API
  // Future method for writing events to device calendar will be added when needed
  // Example: Future<void> addEventToDeviceCalendar(Map<String, dynamic> eventData) async { ... }

  /// Sync alarms with server (mock implementation)
  Future<void> _syncAlarms() async {
    debugPrint('⏰ Syncing alarms...');
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 600));

    // In real implementation, fetch device alarms and send to server:
    // final alarms = await _fetchDeviceAlarms();
    // final response = await http.post(
    //   Uri.parse('${AppConfig.agentApiBaseUrl}/sync/alarms'),
    //   headers: {
    //     'Authorization': 'Bearer ${AppConfig.agentApiKey}',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({'alarms': alarms}),
    // );

    debugPrint('✅ Alarms synced');
  }

  /// Sync call registry with server (mock implementation)
  Future<void> _syncCallRegistry() async {
    debugPrint('📞 Syncing call registry...');
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 650));

    // In real implementation, fetch call logs and send to server:
    // final callLogs = await _fetchCallLogs();
    // final response = await http.post(
    //   Uri.parse('${AppConfig.agentApiBaseUrl}/sync/calls'),
    //   headers: {
    //     'Authorization': 'Bearer ${AppConfig.agentApiKey}',
    //     'Content-Type': 'application/json',
    //   },
    //   body: jsonEncode({'call_logs': callLogs}),
    // );

    debugPrint('✅ Call registry synced');
  }

  /// Get sync status message
  String getSyncStatusMessage() {
    if (_isSyncing) {
      return 'Syncing...';
    }
    if (_lastSyncTime == null) {
      return 'Never synced';
    }
    
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Fetch contacts from device
  Future<List<Map<String, dynamic>>> _fetchDeviceContacts() async {
    final List<Map<String, dynamic>> contactsList = [];
    
    try {
      var status = await Permission.contacts.status;
      debugPrint('📱 Contacts permission INITIAL status: $status');
      debugPrint('   - isGranted: ${status.isGranted}');
      debugPrint('   - isDenied: ${status.isDenied}');
      debugPrint('   - isPermanentlyDenied: ${status.isPermanentlyDenied}');
      debugPrint('   - isLimited: ${status.isLimited}');
      debugPrint('   - isRestricted: ${status.isRestricted}');
      
      if (!status.isGranted) {
        debugPrint('📱 Requesting contacts permission...');
        status = await Permission.contacts.request();
        debugPrint('📱 Contacts permission AFTER request: $status');
        debugPrint('   - isGranted: ${status.isGranted}');
        debugPrint('   - isDenied: ${status.isDenied}');
        debugPrint('   - isPermanentlyDenied: ${status.isPermanentlyDenied}');
      }
      
      if (status.isGranted) {
        debugPrint('✅ Contacts permission granted! Fetching contacts...');
        final contacts = await ContactsService.getContacts();
        debugPrint('📱 Found ${contacts.length} contacts');
        
        for (final contact in contacts) {
          contactsList.add({
            'id': contact.identifier,
            'name': contact.displayName ?? 'Unknown',
            'phones': contact.phones?.map((p) => p.value).toList() ?? [],
            'emails': contact.emails?.map((e) => e.value).toList() ?? [],
          });
        }
      } else if (status.isPermanentlyDenied) {
        debugPrint('⚠️ Contacts permission permanently denied');
        debugPrint('💡 Opening Settings to enable Contacts permission...');
        await openAppSettings();
      } else {
        debugPrint('⚠️ Contacts permission denied');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching contacts: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return contactsList;
  }

  // Calendar reading removed - server handles Google Calendar
  // Future: Add method to write events to device calendar when received from server
  // Future<bool> addEventToDeviceCalendar({
  //   required String title,
  //   required DateTime startDate,
  //   required DateTime endDate,
  //   String? description,
  //   String? location,
  //   bool allDay = false,
  // }) async {
  //   try {
  //     final deviceCalendarPlugin = DeviceCalendarPlugin();
  //     final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
  //     
  //     if (calendarsResult.isSuccess && calendarsResult.data != null && calendarsResult.data!.isNotEmpty) {
  //       final calendar = calendarsResult.data!.first; // Use default calendar
  //       final event = Event(calendar.id);
  //       event.title = title;
  //       event.start = TZDateTime.from(startDate, local);
  //       event.end = TZDateTime.from(endDate, local);
  //       event.description = description;
  //       event.location = location;
  //       event.allDay = allDay;
  //       
  //       final createResult = await deviceCalendarPlugin.createOrUpdateEvent(event);
  //       return createResult?.isSuccess ?? false;
  //     }
  //     return false;
  //   } catch (e) {
  //     debugPrint('❌ Error creating calendar event: $e');
  //     return false;
  //   }
  // }
}
