# Background Sync Implementation Guide

## Overview

EPANSA now has **true background synchronization** that works even when the app is closed. The app uses the `workmanager` package to schedule periodic background tasks that sync data with your agent server.

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────┐
│           User Enables Background Sync          │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│     Workmanager Registers Periodic Task         │
│     • Frequency: Every 15 minutes (minimum)     │
│     • Constraints: WiFi + Battery not low       │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│        OS Schedules Background Execution        │
│        (Android: WorkManager)                   │
│        (iOS: Background Fetch)                  │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│     callbackDispatcher() Runs in Background     │
│     • Independent of main app process           │
│     • Has its own isolated Dart VM              │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│          Sync Data with Server (Mock)           │
│          • Notes                                │
│          • Contacts                             │
│          • Calendar                             │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│         Update Last Sync Time & Exit            │
└─────────────────────────────────────────────────┘
```

### Key Components

#### 1. **callbackDispatcher()** (`lib/services/sync_service.dart`)
- Top-level function that runs in a separate Dart isolate
- Called by the OS when it's time to sync
- Decorated with `@pragma('vm:entry-point')` to prevent tree-shaking
- Independent of the main app - can run even if app is completely closed

#### 2. **SyncService** (`lib/services/sync_service.dart`)
- Manages background sync state and preferences
- Registers/unregisters periodic tasks with Workmanager
- Provides manual sync button functionality
- Tracks last sync time

#### 3. **Workmanager Initialization** (`lib/main.dart`)
- Initialized once at app startup
- Registers the callback dispatcher
- Only runs on mobile (Android/iOS), not web

## Platform-Specific Behavior

### Android
- **Frequency**: Minimum 15 minutes between syncs
- **Constraints**: 
  - Network connectivity required
  - Battery not low (configurable)
- **Reliability**: Very reliable, uses Android's JobScheduler/WorkManager
- **Battery Impact**: Optimized by OS, respects Doze mode
- **User Control**: Users can disable in Settings → Battery optimization

### iOS
- **Frequency**: iOS decides (typically every few hours)
- **Constraints**: System-managed based on usage patterns
- **Reliability**: Less predictable than Android
- **Battery Impact**: Strictly managed by iOS
- **User Control**: Automatic, no user intervention needed
- **Limitations**: 
  - 30-second execution limit per task
  - Deprioritized if app rarely used

### Web
- **Background Sync**: NOT SUPPORTED
- **Fallback**: Only manual sync available
- **Reason**: Browsers don't allow true background tasks when closed

## Configuration

### Sync Frequency
Located in `lib/services/sync_service.dart`:
```dart
await Workmanager().registerPeriodicTask(
  syncTaskName,
  syncTaskTag,
  frequency: const Duration(minutes: 15), // Change this
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
  ),
);
```

**Note**: 
- Android minimum is 15 minutes
- iOS ignores this and uses its own schedule
- Setting lower than 15 minutes will be clamped to 15

### Network Constraints
```dart
networkType: NetworkType.connected, // Any connection
// OR
networkType: NetworkType.unmetered, // WiFi only
// OR  
networkType: NetworkType.not_roaming, // Not roaming
```

### Battery Constraints
```dart
requiresBatteryNotLow: true,  // Skip if battery low
requiresCharging: false,       // Don't require charging
requiresDeviceIdle: false,     // Don't require idle
```

## Testing Background Sync

### Android Testing

#### Method 1: ADB Command (Immediate)
```bash
# Force run the background task immediately
adb shell cmd jobscheduler run -f com.example.epansa_app 1

# Check scheduled jobs
adb shell dumpsys jobscheduler | grep epansa

# Monitor logcat for debug output
adb logcat | grep -i "flutter\|epansa\|sync"
```

#### Method 2: Wait for Natural Execution
- Enable background sync in the app
- Close the app completely
- Wait 15+ minutes
- Check logs: `adb logcat -s flutter`

### iOS Testing

#### Method 1: Xcode Simulator
1. Open Xcode → Debug → Simulate Background Fetch
2. Watch console for sync logs

#### Method 2: Real Device
1. Enable background sync
2. Use app for a while to build "usage patterns"
3. iOS will eventually trigger background fetch (unpredictable)
4. Check logs in Xcode console

### Debug Logging

All background sync operations log to console:
```
🔄 Background sync task triggered: sync-task
📱 Executing background sync...
📝 [Background] Syncing notes...
✅ [Background] Notes synced
👥 [Background] Syncing contacts...
✅ [Background] Contacts synced
📅 [Background] Syncing calendar...
✅ [Background] Calendar synced
✅ Background sync completed
```

## Troubleshooting

### Background Sync Not Working?

#### Android
1. **Check battery optimization**:
   - Settings → Apps → EPANSA → Battery → Don't optimize
   
2. **Check background data**:
   - Settings → Apps → EPANSA → Mobile data & Wi-Fi → Background data: ON

3. **Verify task is registered**:
   ```bash
   adb shell dumpsys jobscheduler | grep epansa
   ```

4. **Force run task**:
   ```bash
   adb shell cmd jobscheduler run -f com.example.epansa_app 1
   ```

#### iOS
1. **Check Background App Refresh**:
   - Settings → General → Background App Refresh → ON
   - Settings → General → Background App Refresh → EPANSA: ON

2. **Build usage patterns**: iOS prioritizes apps you use frequently

3. **Check Info.plist**: Verify `UIBackgroundModes` is set

### Common Issues

#### "Sync already in progress"
- Multiple sync requests at once
- Normal behavior, previous sync will complete

#### "Background sync is disabled, skipping"
- User disabled sync in settings
- Check SharedPreferences: `background_sync_enabled`

#### No logs in background
- Background tasks run in separate process
- Use `adb logcat` or Xcode console, not app debug console

## Converting Mock to Real API

When your agent server is ready, replace the mock functions:

### Current (Mock)
```dart
Future<void> _backgroundSyncNotes() async {
  debugPrint('📝 [Background] Syncing notes...');
  await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('✅ [Background] Notes synced');
}
```

### Real Implementation
```dart
Future<void> _backgroundSyncNotes() async {
  debugPrint('📝 [Background] Syncing notes...');
  
  try {
    // Fetch local notes (would need actual implementation)
    final notes = await _fetchLocalNotes();
    
    // Send to server
    final response = await http.post(
      Uri.parse('${AppConfig.agentApiBaseUrl}/sync/notes'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.agentApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'notes': notes}),
    );
    
    if (response.statusCode == 200) {
      debugPrint('✅ [Background] Notes synced');
    } else {
      throw Exception('Sync failed: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ [Background] Notes sync failed: $e');
    rethrow;
  }
}
```

## Permissions

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

### iOS (`Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

## Performance Considerations

### Battery Impact
- Android: ~1-2% battery per day with 15-min interval
- iOS: Minimal, system-managed
- Recommendation: Use WiFi-only for frequent syncs

### Data Usage
- Depends on sync payload size
- Recommend: Sync diffs only, not full datasets
- Current mock: Negligible

### Execution Time
- Android: No strict limit, but aim for <1 minute
- iOS: 30-second hard limit
- Current mock: ~1.5 seconds

## Best Practices

1. **Always check connectivity** before syncing
2. **Implement exponential backoff** for failures
3. **Sync diffs, not full data** when possible
4. **Respect user's battery optimization settings**
5. **Log all background operations** for debugging
6. **Handle task cancellation gracefully**
7. **Test on real devices**, not just simulators

## User Experience

### What Users See
1. **Setup Screen**: Option to enable background sync
2. **Settings Toggle**: Enable/disable anytime
3. **Last Sync Time**: Displayed in settings
4. **Manual Sync Button**: Always available
5. **Toast Notification**: "Sync completed" feedback

### What Happens Behind the Scenes
1. App registers periodic task with OS
2. OS schedules execution based on constraints
3. Background task runs independently
4. Data syncs with server (when implemented)
5. Last sync time updates automatically
6. User sees updated data next time they open app

## Future Enhancements

- [ ] Implement real device data access (contacts, calendar)
- [ ] Connect to actual agent API server
- [ ] Add conflict resolution for offline changes
- [ ] Implement sync status notifications
- [ ] Add battery usage statistics
- [ ] Support for foreground service (Android) for critical syncs
- [ ] Differential sync (only changed data)
- [ ] Sync history and analytics

## References

- [Workmanager Package](https://pub.dev/packages/workmanager)
- [Android WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager)
- [iOS Background Execution](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
- [Battery Optimization Best Practices](https://developer.android.com/topic/performance/power)
