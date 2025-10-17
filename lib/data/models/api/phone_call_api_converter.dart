import 'package:intl/intl.dart';
import '../phone_call.dart';
import 'phone_call_api_models.dart';

/// Converter to transform local PhoneCall model to backend PhoneCallPayload
class PhoneCallApiConverter {
  /// Convert a local PhoneCall to API PhoneCallPayload
  static PhoneCallPayload toApiPayload(PhoneCall phoneCall) {
    // Format date as YYYY-MM-DD
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final dateString = dateFormatter.format(phoneCall.date);
    
    // Format times as HH:MM:SS (ISO time format)
    final timeFormatter = DateFormat('HH:mm:ss');
    final startTimeString = timeFormatter.format(phoneCall.startTime);
    final endTimeString = timeFormatter.format(phoneCall.endTime);
    
    return PhoneCallPayload(
      call: phoneCall.id,
      sourceApp: 'epansa_app',
      metadata: PhoneCallMetadata(
        date: dateString,
        startTime: startTimeString,
        endTime: endTimeString,
        duration: phoneCall.formattedDuration,
        callDirection: phoneCall.callDirection,
        withContact: phoneCall.withContact,
      ),
      kind: 'call',
    );
  }

  /// Convert API PhoneCallPayload to local PhoneCall
  /// Note: This is mainly for consistency; typically we read calls from device
  static PhoneCall fromApiPayload(PhoneCallPayload payload) {
    // Parse date (YYYY-MM-DD)
    final date = DateTime.parse(payload.metadata.date);
    
    // Parse times (HH:MM:SS) - combine with date
    final startTimeParts = payload.metadata.startTime.split(':');
    final startTime = DateTime(
      date.year, date.month, date.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
      int.parse(startTimeParts[2]),
    );
    
    final endTimeParts = payload.metadata.endTime.split(':');
    final endTime = DateTime(
      date.year, date.month, date.day,
      int.parse(endTimeParts[0]),
      int.parse(endTimeParts[1]),
      int.parse(endTimeParts[2]),
    );
    
    // Parse duration (MM:SS or HH:MM:SS) back to seconds
    final durationParts = payload.metadata.duration.split(':');
    int durationSeconds;
    if (durationParts.length == 3) {
      // HH:MM:SS
      durationSeconds = int.parse(durationParts[0]) * 3600 +
                       int.parse(durationParts[1]) * 60 +
                       int.parse(durationParts[2]);
    } else {
      // MM:SS
      durationSeconds = int.parse(durationParts[0]) * 60 +
                       int.parse(durationParts[1]);
    }
    
    final now = DateTime.now();
    return PhoneCall(
      id: payload.call,
      date: date,
      startTime: startTime,
      endTime: endTime,
      duration: durationSeconds,
      callDirection: payload.metadata.callDirection,
      withContact: payload.metadata.withContact,
      createdAt: now,
      isSyncedToBackend: true, // Coming from API, so it's synced
      lastSyncedAt: now,
    );
  }
}
