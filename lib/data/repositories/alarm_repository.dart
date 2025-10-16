import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epansa_app/data/models/alarm.dart';

/// Repository for managing alarm data in local storage
class AlarmRepository {
  static const String _alarmsKey = 'user_alarms';

  /// Get all alarms from local storage
  Future<List<Alarm>> getAllAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(_alarmsKey);
      
      if (alarmsJson == null || alarmsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = json.decode(alarmsJson);
      return decoded.map((json) => Alarm.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading alarms: $e');
      return [];
    }
  }

  /// Save an alarm to local storage
  Future<bool> saveAlarm(Alarm alarm) async {
    try {
      final alarms = await getAllAlarms();
      
      // Check if alarm with this ID already exists
      final existingIndex = alarms.indexWhere((a) => a.id == alarm.id);
      
      if (existingIndex >= 0) {
        // Update existing alarm
        alarms[existingIndex] = alarm.copyWith(updatedAt: DateTime.now());
      } else {
        // Add new alarm
        alarms.add(alarm);
      }

      await _saveAllAlarms(alarms);
      return true;
    } catch (e) {
      print('❌ Error saving alarm: $e');
      return false;
    }
  }

  /// Delete an alarm from local storage
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      final alarms = await getAllAlarms();
      alarms.removeWhere((a) => a.id == alarmId);
      await _saveAllAlarms(alarms);
      return true;
    } catch (e) {
      print('❌ Error deleting alarm: $e');
      return false;
    }
  }

  /// Update alarm enabled status
  Future<bool> toggleAlarmEnabled(String alarmId, bool enabled) async {
    try {
      final alarms = await getAllAlarms();
      final index = alarms.indexWhere((a) => a.id == alarmId);
      
      if (index >= 0) {
        alarms[index] = alarms[index].copyWith(
          enabled: enabled,
          updatedAt: DateTime.now(),
        );
        await _saveAllAlarms(alarms);
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error toggling alarm: $e');
      return false;
    }
  }

  /// Get a specific alarm by ID
  Future<Alarm?> getAlarm(String alarmId) async {
    try {
      final alarms = await getAllAlarms();
      return alarms.firstWhere(
        (a) => a.id == alarmId,
        orElse: () => throw Exception('Alarm not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear all alarms (use with caution)
  Future<bool> clearAllAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_alarmsKey);
      return true;
    } catch (e) {
      print('❌ Error clearing alarms: $e');
      return false;
    }
  }

  /// Private helper to save all alarms
  Future<void> _saveAllAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = json.encode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_alarmsKey, alarmsJson);
  }
}
