import 'package:flutter/material.dart';
import 'package:epansa_app/data/models/alarm.dart';
import 'package:epansa_app/data/repositories/alarm_repository.dart';
import 'package:epansa_app/services/alarm_service.dart';
import 'package:epansa_app/data/api/agent_api_client.dart';

/// Provider for managing alarm state
class AlarmProvider extends ChangeNotifier {
  final AlarmRepository _repository;
  final AlarmService _alarmService;
  final AgentApiClient _apiClient;

  List<Alarm> _alarms = [];
  bool _isLoading = false;
  String? _error;

  List<Alarm> get alarms => List.unmodifiable(_alarms);
  bool get isLoading => _isLoading;
  String? get error => _error;

  AlarmProvider({
    AlarmRepository? repository,
    required AlarmService alarmService,
    AgentApiClient? apiClient,
  })  : _repository = repository ?? AlarmRepository(),
        _alarmService = alarmService,
        _apiClient = apiClient ?? AgentApiClient(useMockData: true);

  /// Load all alarms from storage
  Future<void> loadAlarms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alarms = await _repository.getAllAlarms();
      _alarms.sort((a, b) {
        // Sort by time (hour, then minute)
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
    } catch (e) {
      _error = 'Failed to load alarms: $e';
      debugPrint('❌ Error loading alarms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new alarm
  Future<bool> createAlarm({
    required int hour,
    required int minute,
    required String label,
    required bool enabled,
    required List<int> repeatDays,
  }) async {
    try {
      _error = null;
      
      final alarm = Alarm.create(
        hour: hour,
        minute: minute,
        label: label,
        enabled: enabled,
        repeatDays: repeatDays,
      );

      // Save to local storage
      final saved = await _repository.saveAlarm(alarm);
      if (!saved) {
        _error = 'Failed to save alarm to storage';
        notifyListeners();
        return false;
      }

      // Set system alarm if enabled
      if (enabled) {
        await _setSystemAlarm(alarm);
      }

      // Notify backend (mock for now)
      await _notifyBackend(alarm, 'created');

      // Reload alarms
      await loadAlarms();
      
      debugPrint('✅ Alarm created: ${alarm.formattedTime} - $label');
      return true;
    } catch (e) {
      _error = 'Failed to create alarm: $e';
      debugPrint('❌ Error creating alarm: $e');
      notifyListeners();
      return false;
    }
  }

  /// Update an existing alarm
  Future<bool> updateAlarm(Alarm alarm) async {
    try {
      _error = null;

      // Save to local storage
      final saved = await _repository.saveAlarm(alarm);
      if (!saved) {
        _error = 'Failed to update alarm';
        notifyListeners();
        return false;
      }

      // Update system alarm
      if (alarm.enabled) {
        await _setSystemAlarm(alarm);
      } else {
        // TODO: Cancel system alarm (not currently supported)
        debugPrint('⚠️ Alarm disabled but system alarm cancellation not implemented');
      }

      // Notify backend
      await _notifyBackend(alarm, 'updated');

      // Reload alarms
      await loadAlarms();
      
      debugPrint('✅ Alarm updated: ${alarm.formattedTime} - ${alarm.label}');
      return true;
    } catch (e) {
      _error = 'Failed to update alarm: $e';
      debugPrint('❌ Error updating alarm: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete an alarm
  Future<bool> deleteAlarm(String alarmId) async {
    try {
      _error = null;

      final alarm = _alarms.firstWhere((a) => a.id == alarmId);
      
      // Delete from local storage
      final deleted = await _repository.deleteAlarm(alarmId);
      if (!deleted) {
        _error = 'Failed to delete alarm';
        notifyListeners();
        return false;
      }

      // TODO: Cancel system alarm (not currently supported)
      debugPrint('⚠️ System alarm cancellation not implemented');

      // Notify backend
      await _notifyBackend(alarm, 'deleted');

      // Reload alarms
      await loadAlarms();
      
      debugPrint('✅ Alarm deleted: ${alarm.formattedTime}');
      return true;
    } catch (e) {
      _error = 'Failed to delete alarm: $e';
      debugPrint('❌ Error deleting alarm: $e');
      notifyListeners();
      return false;
    }
  }

  /// Toggle alarm enabled status
  Future<bool> toggleAlarm(String alarmId) async {
    try {
      _error = null;

      final alarm = _alarms.firstWhere((a) => a.id == alarmId);
      final newEnabled = !alarm.enabled;
      
      // Update in storage
      final updated = await _repository.toggleAlarmEnabled(alarmId, newEnabled);
      if (!updated) {
        _error = 'Failed to toggle alarm';
        notifyListeners();
        return false;
      }

      // Update system alarm
      final updatedAlarm = alarm.copyWith(enabled: newEnabled);
      if (newEnabled) {
        await _setSystemAlarm(updatedAlarm);
      } else {
        // TODO: Cancel system alarm
        debugPrint('⚠️ System alarm cancellation not implemented');
      }

      // Notify backend
      await _notifyBackend(updatedAlarm, 'toggled');

      // Reload alarms
      await loadAlarms();
      
      debugPrint('✅ Alarm toggled: ${alarm.formattedTime} -> $newEnabled');
      return true;
    } catch (e) {
      _error = 'Failed to toggle alarm: $e';
      debugPrint('❌ Error toggling alarm: $e');
      notifyListeners();
      return false;
    }
  }

  /// Set system alarm using AlarmService
  Future<void> _setSystemAlarm(Alarm alarm) async {
    try {
      final now = DateTime.now();
      var alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour,
        alarm.minute,
      );

      // If alarm time has passed today, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      await _alarmService.createAlarm(
        label: alarm.label,
        time: TimeOfDay(hour: alarm.hour, minute: alarm.minute),
        repeatDays: alarm.repeatDays,
        skipUi: true,
      );

      debugPrint('✅ System alarm set: ${alarm.formattedTime}');
    } catch (e) {
      debugPrint('❌ Failed to set system alarm: $e');
      // Don't throw - alarm is saved even if system alarm fails
    }
  }

  /// Notify backend about alarm changes (mock for now)
  Future<void> _notifyBackend(Alarm alarm, String action) async {
    try {
      debugPrint('📡 Notifying backend: $action alarm ${alarm.formattedTime}');
      
      // TODO: Replace with real API call
      // await _apiClient.syncAlarms([alarm.toJson()]);
      
      // Mock notification for now
      await Future.delayed(const Duration(milliseconds: 100));
      
      debugPrint('✅ Backend notified: $action alarm');
    } catch (e) {
      debugPrint('⚠️ Failed to notify backend: $e');
      // Don't throw - local alarm is still valid
    }
  }

  /// Get active alarms (enabled only)
  List<Alarm> get activeAlarms => _alarms.where((a) => a.enabled).toList();

  /// Get inactive alarms (disabled only)
  List<Alarm> get inactiveAlarms => _alarms.where((a) => !a.enabled).toList();
}
