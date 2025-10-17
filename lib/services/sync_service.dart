import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:epansa_app/data/api/agent_api_client.dart';
import 'package:epansa_app/data/repositories/contact_repository.dart';
import 'package:epansa_app/data/repositories/phone_call_repository.dart';
import 'package:epansa_app/data/models/contact.dart' as epansa;
import 'package:epansa_app/data/models/phone_call.dart';
import 'package:epansa_app/data/models/api/contact_api_converter.dart';
import 'package:epansa_app/data/models/api/phone_call_api_converter.dart';

// Background task identifier
const String syncTaskName = "epansa-background-sync";
const String syncTaskTag = "sync-task";

// Notification plugin (initialized in main.dart or here)
final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

/// Initialize notifications for background sync indicator
/// This runs in the background isolate
Future<void> _initializeNotificationsForBackground() async {
  if (kIsWeb) return;
  
  try {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Silent notifications
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin.initialize(settings);
  } catch (e) {
    debugPrint('⚠️ Failed to initialize notifications in background: $e');
  }
}

/// Show silent notification during background sync
/// This notification is silent (no sound/vibration) and can be hidden in notification shade
Future<void> _showSilentSyncNotification({required bool isStarting}) async {
  try {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'background_sync_channel',
      'Background Sync',
      channelDescription: 'Silent background data synchronization',
      importance: Importance.low, // Low importance = no sound/vibration
      priority: Priority.low,
      showWhen: false,
      ongoing: true, // Makes it persistent while syncing
      autoCancel: false,
      silent: true, // Completely silent
      visibility: NotificationVisibility.secret, // Hidden from lock screen
    );
    
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    if (isStarting) {
      await _notificationsPlugin.show(
        999, // Notification ID
        'EPANSA',
        'Syncing data in background...',
        details,
      );
    } else {
      // Update to show completion, then auto-dismiss after 2 seconds
      await _notificationsPlugin.show(
        999,
        'EPANSA',
        'Sync completed',
        details,
      );
      await Future.delayed(const Duration(seconds: 2));
      await _notificationsPlugin.cancel(999);
    }
  } catch (e) {
    debugPrint('⚠️ Failed to show sync notification: $e');
  }
}

/// Background callback dispatcher - runs independently of the app
/// This function is called by the OS when it's time to sync
/// 
/// IMPORTANT: This runs in an isolate separate from the main app,
/// so it can execute even when the app is completely closed
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Background sync task triggered: $task');
    debugPrint('📱 App state: CLOSED or BACKGROUND');
    
    try {
      // Initialize notifications for silent sync indicator (optional)
      await _initializeNotificationsForBackground();
      
      // Show silent notification (Android) - won't disturb user
      if (!kIsWeb && Platform.isAndroid) {
        await _showSilentSyncNotification(isStarting: true);
      }
      
      // Perform the background sync
      await _performBackgroundSyncTask();
      
      // Update notification to show completion
      if (!kIsWeb && Platform.isAndroid) {
        await _showSilentSyncNotification(isStarting: false);
      }
      
      debugPrint('✅ Background sync task completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background sync task failed: $e');
      
      // Clear notification on error
      if (!kIsWeb && Platform.isAndroid) {
        await _notificationsPlugin.cancel(999);
      }
      
      return Future.value(false);
    }
  });
}

/// Performs the actual sync work in the background
/// This is separate from the service class so it can run independently
/// 
/// CRITICAL: This function runs in a background isolate on Android,
/// meaning it executes even when the app is completely terminated
Future<void> _performBackgroundSyncTask() async {
  debugPrint('📱 Executing background sync (app may be closed)...');
  
  // Check if background sync is enabled
  final prefs = await SharedPreferences.getInstance();
  final isEnabled = prefs.getBool('background_sync_enabled') ?? false;
  
  if (!isEnabled) {
    debugPrint('⚠️ Background sync is disabled, skipping');
    return;
  }
  
  // Perform mock sync operations
  debugPrint('🔄 Starting mock sync operations...');
  await _backgroundSyncContacts();
  // Calendar reading removed - handled by server reading Google Calendar
  await _backgroundSyncAlarms();
  await _backgroundSyncCallRegistry();
  
  // Update last sync time
  await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
  debugPrint('✅ Background sync completed (app may still be closed)');
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

/// Service for syncing user data (contacts, calendar) with the agent server
/// 
/// BACKGROUND SYNC CAPABILITIES:
/// - Android: Uses WorkManager for true background execution (runs even when app is closed)
/// - iOS: Uses background fetch (limited by OS, typically runs when charging/WiFi)
/// - Silent notifications: Optional visual indicator (can be completely hidden)
class SyncService extends ChangeNotifier {
  bool _isBackgroundSyncEnabled = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isBackgroundSyncEnabled => _isBackgroundSyncEnabled;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Notification plugin for foreground notifications
  final FlutterLocalNotificationsPlugin _foregroundNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Dependencies for syncing (optional, may not be available in background isolate)
  AgentApiClient? _apiClient;
  ContactRepository? _contactRepository;
  PhoneCallRepository? _phoneCallRepository;

  SyncService({
    AgentApiClient? apiClient,
    ContactRepository? contactRepository,
    PhoneCallRepository? phoneCallRepository,
  }) : _apiClient = apiClient,
       _contactRepository = contactRepository,
       _phoneCallRepository = phoneCallRepository {
    _loadSyncPreferences();
    _initializeForegroundNotifications();
  }
  
  /// Initialize notifications for foreground sync (when app is open)
  Future<void> _initializeForegroundNotifications() async {
    if (kIsWeb) return;
    
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _foregroundNotificationsPlugin.initialize(settings);
      
      // Create notification channel for Android
      if (!kIsWeb && Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'background_sync_channel',
          'Background Sync',
          description: 'Silent background data synchronization',
          importance: Importance.low,
          showBadge: false,
        );
        
        await _foregroundNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to initialize foreground notifications: $e');
    }
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

  /// Enable background sync with silent notifications
  /// 
  /// This enables true background sync that runs even when the app is closed:
  /// - Android: WorkManager executes every 15-30 minutes (OS optimized)
  /// - iOS: Background fetch when conditions are favorable (charging, WiFi)
  /// - Silent notifications provide optional visual feedback
  Future<void> enableBackgroundSync() async {
    debugPrint('📱 Enabling background sync (works even when app is closed)...');
    
    // Request notification permission (for silent sync indicator)
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          final androidImpl = _foregroundNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          await androidImpl?.requestNotificationsPermission();
        } else if (Platform.isIOS) {
          final iosImpl = _foregroundNotificationsPlugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
          await iosImpl?.requestPermissions(
            alert: false, // No alerts
            badge: false, // No badge
            sound: false, // No sound
          );
        }
      } catch (e) {
        debugPrint('⚠️ Notification permission request failed: $e');
      }
    }
    
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
        // iOS: Enable background fetch
        // Note: iOS background fetch is opportunistic and controlled by the OS
        // It typically runs when device is charging and on WiFi
        debugPrint('⚠️ iOS background sync is limited by the OS');
        debugPrint('💡 iOS will sync when charging/WiFi (controlled by system)');
        debugPrint('💡 For testing: Settings > Developer > Background Fetch');
        
        // iOS still benefits from WorkManager for foreground periodic sync
        await Workmanager().registerPeriodicTask(
          syncTaskName,
          syncTaskTag,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        );
      } else {
        // Android: Register periodic task with WorkManager
        // This WILL run even when app is completely closed
        await Workmanager().registerPeriodicTask(
          syncTaskName,
          syncTaskTag,
          frequency: const Duration(minutes: 15), // Minimum 15 minutes
          constraints: Constraints(
            networkType: NetworkType.connected, // Only sync when connected to internet
            requiresBatteryNotLow: true, // Don't sync if battery is low
            requiresCharging: false, // Can sync while not charging
            requiresDeviceIdle: false, // Can sync while device is in use
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(minutes: 1),
        );
        debugPrint('✅ Android WorkManager registered - will run even when app is closed');
        debugPrint('📱 Sync will occur every 15-30 minutes (OS optimized)');
      }
    } catch (e) {
      debugPrint('❌ Failed to register background task: $e');
    }

    // Perform initial sync
    await performSync();

    debugPrint('✅ Background sync enabled (app-closed sync active)');
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
      // Sync contacts and calls in alternating batches
      await _syncContactsAndCallsInBatches();
      
      // Calendar reading removed - server handles Google Calendar
      await _syncAlarms();

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

  /// Sync contacts and phone calls in alternating batches
  /// This method syncs 5 contacts, then 5 calls, alternating until all are synced
  Future<void> _syncContactsAndCallsInBatches() async {
    debugPrint('🔄 Starting alternating batch sync (5 contacts, then 5 calls, with 10s delay)...');
    
    // Check if dependencies are available
    if (_apiClient == null || _contactRepository == null || _phoneCallRepository == null) {
      debugPrint('⚠️ Required repositories not available, skipping sync');
      return;
    }
    
    try {
      // Fetch and prepare contacts
      final contactsData = await _fetchDeviceContacts();
      debugPrint('📱 Fetched ${contactsData.length} contacts from device');
      
      final List<epansa.Contact> localContacts = [];
      for (var contactData in contactsData) {
        final phones = contactData['phones'] as List<dynamic>;
        if (phones.isEmpty) continue;
        
        final phoneNumber = phones[0].toString();
        final contactId = contactData['id'] as String;
        final contactName = contactData['name'] as String;
        
        final existingContact = await _contactRepository!.getContact(contactId);
        
        if (existingContact != null) {
          if (existingContact.name != contactName || existingContact.phoneNumber != phoneNumber) {
            final updatedContact = existingContact.copyWith(
              name: contactName,
              phoneNumber: phoneNumber,
              updatedAt: DateTime.now(),
              isSyncedToBackend: false,
            );
            localContacts.add(updatedContact);
          } else {
            localContacts.add(existingContact);
          }
        } else {
          final localContact = epansa.Contact.create(
            id: contactId,
            name: contactName,
            phoneNumber: phoneNumber,
          );
          localContacts.add(localContact);
        }
      }
      
      await _contactRepository!.saveContacts(localContacts);
      
      // Fetch and prepare phone calls
      final callLogsData = await _fetchCallLogs();
      debugPrint('📱 Fetched ${callLogsData.length} call logs from device');
      
      final List<PhoneCall> localCalls = [];
      for (var callData in callLogsData) {
        final timestamp = callData['timestamp'] as int;
        final duration = callData['duration'] as int;
        final phoneNumber = callData['number'] as String;
        final contactName = callData['name'] as String;
        
        final callId = '${timestamp}_${phoneNumber.replaceAll(RegExp(r'[^\d]'), '')}';
        final callDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final startTime = callDate;
        final endTime = startTime.add(Duration(seconds: duration));
        
        final callType = callData['type'] as String;
        String callDirection;
        switch (callType) {
          case 'incoming':
          case 'INCOMING':
            callDirection = 'incoming';
            break;
          case 'outgoing':
          case 'OUTGOING':
            callDirection = 'outgoing';
            break;
          case 'missed':
          case 'MISSED':
            callDirection = 'missed';
            break;
          default:
            callDirection = 'missed';
        }
        
        final existingCall = await _phoneCallRepository!.getCall(callId);
        
        if (existingCall != null) {
          localCalls.add(existingCall);
        } else {
          final localCall = PhoneCall.create(
            id: callId,
            date: callDate,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            callDirection: callDirection,
            withContact: contactName != 'Unknown' ? contactName : null,
            phoneNumber: phoneNumber,
          );
          localCalls.add(localCall);
        }
      }
      
      await _phoneCallRepository!.saveCalls(localCalls);
      
      // Get unsynced items
      final unsyncedContacts = await _contactRepository!.getUnsyncedContacts();
      final unsyncedCalls = await _phoneCallRepository!.getUnsyncedCalls();
      
      debugPrint('🔍 Found ${unsyncedContacts.length} unsynced contacts');
      debugPrint('🔍 Found ${unsyncedCalls.length} unsynced calls');
      
      if (unsyncedContacts.isEmpty && unsyncedCalls.isEmpty) {
        debugPrint('✅ All contacts and calls already synced to backend');
        return;
      }
      
      // Batch size: 5 items per batch
      const batchSize = 5;
      int contactIndex = 0;
      int callIndex = 0;
      int totalSynced = 0;
      
      // Alternate between contacts and calls
      while (contactIndex < unsyncedContacts.length || callIndex < unsyncedCalls.length) {
        // Sync batch of contacts
        if (contactIndex < unsyncedContacts.length) {
          final contactBatch = unsyncedContacts
              .skip(contactIndex)
              .take(batchSize)
              .toList();
          
          debugPrint('📧 Syncing contacts batch: ${contactIndex + 1}-${contactIndex + contactBatch.length} of ${unsyncedContacts.length}');
          
          for (int i = 0; i < contactBatch.length; i++) {
            final contact = contactBatch[i];
            try {
              final payload = ContactApiConverter.toApiPayload(contact);
              await _apiClient!.addContact(payload);
              await _contactRepository!.markAsSynced(contact.id);
              totalSynced++;
              debugPrint('✅ Synced contact ${contactIndex + i + 1}/${unsyncedContacts.length}: ${contact.name}');
              
              // Add 10 second delay between calls
              if (i < contactBatch.length - 1 || callIndex < unsyncedCalls.length) {
                debugPrint('⏳ Waiting 10 seconds...');
                await Future.delayed(const Duration(seconds: 10));
              }
            } catch (e) {
              debugPrint('⚠️ Failed to sync contact ${contact.name}: $e');
              await Future.delayed(const Duration(seconds: 10));
            }
          }
          
          contactIndex += contactBatch.length;
        }
        
        // Sync batch of calls
        if (callIndex < unsyncedCalls.length) {
          final callBatch = unsyncedCalls
              .skip(callIndex)
              .take(batchSize)
              .toList();
          
          debugPrint('📞 Syncing calls batch: ${callIndex + 1}-${callIndex + callBatch.length} of ${unsyncedCalls.length}');
          
          for (int i = 0; i < callBatch.length; i++) {
            final call = callBatch[i];
            try {
              final payload = PhoneCallApiConverter.toApiPayload(call);
              await _apiClient!.addPhoneCall(payload);
              await _phoneCallRepository!.markAsSynced(call.id);
              totalSynced++;
              debugPrint('✅ Synced call ${callIndex + i + 1}/${unsyncedCalls.length}: ${call.callDirection} (${call.withContact ?? "Unknown"})');
              
              // Add 10 second delay between calls
              if (i < callBatch.length - 1 || contactIndex < unsyncedContacts.length) {
                debugPrint('⏳ Waiting 10 seconds...');
                await Future.delayed(const Duration(seconds: 10));
              }
            } catch (e) {
              debugPrint('⚠️ Failed to sync call ${call.id}: $e');
              await Future.delayed(const Duration(seconds: 10));
            }
          }
          
          callIndex += callBatch.length;
        }
      }
      
      debugPrint('✅ Batch sync completed: $totalSynced items synced in total');
      
      // Update last sync times
      if (contactIndex > 0) {
        await _contactRepository!.updateLastSyncTime(DateTime.now());
      }
      if (callIndex > 0) {
        await _phoneCallRepository!.updateLastSyncTime(DateTime.now());
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error in batch sync: $e');
      debugPrint('Stack trace: $stackTrace');
    }
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
      // flutter_contacts handles permissions internally
      if (await FlutterContacts.requestPermission()) {
        debugPrint('✅ Contacts permission granted! Fetching contacts...');
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        debugPrint('📱 Found ${contacts.length} contacts');
        
        for (final contact in contacts) {
          contactsList.add({
            'id': contact.id,
            'name': contact.displayName,
            'phones': contact.phones.map((p) => p.number).toList(),
            'emails': contact.emails.map((e) => e.address).toList(),
          });
        }
      } else {
        debugPrint('⚠️ Contacts permission denied');
        debugPrint('💡 Opening Settings to enable Contacts permission...');
        await openAppSettings();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching contacts: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return contactsList;
  }

  // Calendar reading removed - server handles Google Calendar
  // Future: Add method to write events to device calendar when received from server

  /// Fetch call logs from device (Android only)
  Future<List<Map<String, dynamic>>> _fetchCallLogs() async {
    final List<Map<String, dynamic>> callLogsList = [];
    
    // Call logs are only available on Android
    if (!Platform.isAndroid) {
      debugPrint('ℹ️ Call logs are only available on Android');
      return callLogsList;
    }
    
    try {
      var status = await Permission.phone.status;
      debugPrint('📞 Phone permission INITIAL status: $status');
      
      if (!status.isGranted) {
        debugPrint('📞 Requesting phone permission...');
        status = await Permission.phone.request();
        debugPrint('📞 Phone permission AFTER request: $status');
      }
      
      if (status.isGranted) {
        debugPrint('✅ Phone permission granted! Fetching call logs...');
        
        final Iterable<CallLogEntry> entries = await CallLog.get();
        debugPrint('📞 Found ${entries.length} call log entries');
        
        for (final entry in entries) {
          callLogsList.add({
            'name': entry.name ?? 'Unknown',
            'number': entry.number ?? '',
            'type': entry.callType?.name ?? 'unknown',
            'duration': entry.duration ?? 0,
            'timestamp': entry.timestamp ?? 0,
          });
        }
      } else {
        debugPrint('⚠️ Phone permission denied');
        if (status.isPermanentlyDenied) {
          debugPrint('💡 Opening Settings to enable Phone permission...');
          await openAppSettings();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching call logs: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    
    return callLogsList;
  }

  /// Get top N contacts from device (for UI display)
  Future<List<Map<String, dynamic>>> getTopContacts({int limit = 3}) async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        
        // Return top N contacts
        final topContacts = contacts.take(limit).map((contact) {
          return {
            'id': contact.id,
            'name': contact.displayName,
            'phones': contact.phones.map((p) => p.number).toList(),
            'emails': contact.emails.map((e) => e.address).toList(),
          };
        }).toList();
        
        return topContacts;
      } else {
        debugPrint('⚠️ Contacts permission denied');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting top contacts: $e');
      return [];
    }
  }
}
