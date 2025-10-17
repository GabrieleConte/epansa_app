import 'package:epansa_app/data/models/alarm.dart';
import 'package:epansa_app/data/models/api/alarm_api_models.dart';
import 'package:intl/intl.dart';

/// Extension to convert local Alarm model to backend API format
extension AlarmApiConverter on Alarm {
  /// Convert to AlarmPayload for backend API
  AlarmPayload toApiPayload() {
    // Determine if it's a recurrent alarm based on repeatFrequency
    final bool isRecurrent = repeatFrequency != null && 
                             repeatFrequency != 'once' && 
                             repeatFrequency!.isNotEmpty;
    
    final String timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    AlarmMetadata metadata;
    String recurrenceType;

    if (isRecurrent) {
      // Recurrent alarm (daily, weekly, monthly, yearly)
      recurrenceType = 'recurrent';
      metadata = RecurrentAlarmMetadata(
        label: label,
        time: timeStr,
        repeatFrequency: repeatFrequency!,
        on: _formatRepeatOn(),
      );
    } else {
      // Single occurrence alarm - use tomorrow's date as default
      recurrenceType = 'single-occurrence';
      final now = DateTime.now();
      final alarmDateTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the time has passed today, schedule for tomorrow
      final targetDate = alarmDateTime.isBefore(now)
          ? alarmDateTime.add(const Duration(days: 1))
          : alarmDateTime;

      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);

      metadata = SingleAlarmMetadata(
        label: label,
        date: dateStr,
        time: timeStr,
      );
    }

    return AlarmPayload(
      alarm: id,
      sourceApp: 'epansa_app',
      recurrenceType: recurrenceType,
      metadata: metadata,
    );
  }

  /// Format repeat "on" field based on frequency
  /// - daily: "Every day"
  /// - weekly: "Mon, Wed, Fri" or "Every day" or "MO,TU,WE"
  /// - monthly: "15" (day of month) or "3 TU" (3rd Tuesday)
  /// - yearly: "11-Sep" (day-month)
  String _formatRepeatOn() {
    if (repeatFrequency == 'daily') {
      return 'Every day';
    }
    
    if (repeatFrequency == 'weekly') {
      return _formatWeeklyRepeatDays();
    }
    
    if (repeatFrequency == 'monthly' || repeatFrequency == 'yearly') {
      // Use the repeatOn field directly if set
      if (repeatOn != null && repeatOn!.isNotEmpty) {
        return repeatOn!;
      }
      // Default fallback
      return repeatFrequency == 'monthly' ? '1' : '01-Jan';
    }
    
    return '';
  }

  /// Format repeat days for weekly alarms (e.g., "Mon, Wed, Fri" or "Every day")
  String _formatWeeklyRepeatDays() {
    if (repeatDays.isEmpty) {
      return 'Never';
    }

    if (repeatDays.length == 7) {
      return 'Every day';
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = repeatDays.map((day) => dayNames[day - 1]).toList();
    
    return selectedDays.join(', ');
  }
}
