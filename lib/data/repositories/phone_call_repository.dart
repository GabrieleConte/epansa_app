import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/phone_call.dart';

/// Repository for managing phone call logs locally
/// Stores phone calls in SharedPreferences
class PhoneCallRepository {
  static const String _callsKey = 'phone_calls';
  static const String _lastSyncKey = 'phone_calls_last_sync';

  /// Get all phone calls
  Future<List<PhoneCall>> getAllCalls() async {
    final prefs = await SharedPreferences.getInstance();
    final callsJson = prefs.getStringList(_callsKey) ?? [];
    
    return callsJson
        .map((json) => PhoneCall.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  /// Get a single phone call by ID
  Future<PhoneCall?> getCall(String id) async {
    final calls = await getAllCalls();
    try {
      return calls.firstWhere((call) => call.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a phone call (create or update)
  Future<void> saveCall(PhoneCall call) async {
    final calls = await getAllCalls();
    
    // Remove existing call with same ID if present
    calls.removeWhere((c) => c.id == call.id);
    
    // Add the call
    calls.add(call);
    
    // Save to storage
    await _saveAllCalls(calls);
  }

  /// Save multiple phone calls (bulk operation)
  Future<void> saveCalls(List<PhoneCall> newCalls) async {
    final existingCalls = await getAllCalls();
    
    // Create a map of existing calls by ID for quick lookup
    final callMap = {for (var c in existingCalls) c.id: c};
    
    // Update or add new calls
    for (var call in newCalls) {
      callMap[call.id] = call;
    }
    
    // Save all calls
    await _saveAllCalls(callMap.values.toList());
  }

  /// Delete a phone call
  Future<void> deleteCall(String id) async {
    final calls = await getAllCalls();
    calls.removeWhere((call) => call.id == id);
    await _saveAllCalls(calls);
  }

  /// Clear all phone calls
  Future<void> clearAllCalls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_callsKey);
    await prefs.remove(_lastSyncKey);
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  /// Get phone calls count
  Future<int> getCallsCount() async {
    final calls = await getAllCalls();
    return calls.length;
  }

  /// Check if a phone call exists
  Future<bool> callExists(String id) async {
    final call = await getCall(id);
    return call != null;
  }

  /// Get only unsynced phone calls (not yet sent to backend)
  Future<List<PhoneCall>> getUnsyncedCalls() async {
    final allCalls = await getAllCalls();
    return allCalls.where((call) => !call.isSyncedToBackend).toList();
  }

  /// Mark a phone call as synced to backend
  Future<void> markAsSynced(String callId) async {
    final call = await getCall(callId);
    if (call != null) {
      final syncedCall = call.copyWith(
        isSyncedToBackend: true,
        lastSyncedAt: DateTime.now(),
      );
      await saveCall(syncedCall);
    }
  }

  /// Mark multiple phone calls as synced (bulk operation)
  Future<void> markMultipleAsSynced(List<String> callIds) async {
    final calls = await getAllCalls();
    final updatedCalls = calls.map((call) {
      if (callIds.contains(call.id)) {
        return call.copyWith(
          isSyncedToBackend: true,
          lastSyncedAt: DateTime.now(),
        );
      }
      return call;
    }).toList();
    
    await _saveAllCalls(updatedCalls);
  }

  /// Get recent calls (last N days)
  Future<List<PhoneCall>> getRecentCalls({int days = 7}) async {
    final allCalls = await getAllCalls();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return allCalls
        .where((call) => call.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  // Private helper to save all calls
  Future<void> _saveAllCalls(List<PhoneCall> calls) async {
    final prefs = await SharedPreferences.getInstance();
    final callsJson = calls
        .map((call) => jsonEncode(call.toJson()))
        .toList();
    await prefs.setStringList(_callsKey, callsJson);
  }
}
