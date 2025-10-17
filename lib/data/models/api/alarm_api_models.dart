/// API models for alarm sync with backend
/// These match the OpenAPI schema from the backend

/// Base class for alarm metadata (single or recurrent)
abstract class AlarmMetadata {
  Map<String, dynamic> toJson();
}

/// Metadata for a one-time alarm
class SingleAlarmMetadata extends AlarmMetadata {
  final String label;
  final String date; // Format: YYYY-MM-DD
  final String time; // Format: HH:MM (24-hour)

  SingleAlarmMetadata({
    required this.label,
    required this.date,
    required this.time,
  });

  @override
  Map<String, dynamic> toJson() => {
        'label': label,
        'date': date,
        'time': time,
      };

  factory SingleAlarmMetadata.fromJson(Map<String, dynamic> json) {
    return SingleAlarmMetadata(
      label: json['label'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
    );
  }
}

/// Metadata for a recurring alarm
class RecurrentAlarmMetadata extends AlarmMetadata {
  final String label;
  final String time; // Format: HH:MM (24-hour)
  final String repeatFrequency; // e.g., "daily", "weekly"
  final String on; // e.g., "Mon, Wed, Fri" or "Every day"

  RecurrentAlarmMetadata({
    required this.label,
    required this.time,
    required this.repeatFrequency,
    required this.on,
  });

  @override
  Map<String, dynamic> toJson() => {
        'label': label,
        'time': time,
        'repeat_frequency': repeatFrequency,
        'on': on,
      };

  factory RecurrentAlarmMetadata.fromJson(Map<String, dynamic> json) {
    return RecurrentAlarmMetadata(
      label: json['label'] as String,
      time: json['time'] as String,
      repeatFrequency: json['repeat_frequency'] as String,
      on: json['on'] as String,
    );
  }
}

/// Main alarm payload for API requests
class AlarmPayload {
  final String alarm; // The alarm ID from local app
  final String sourceApp; // "epansa_app"
  final String recurrenceType; // "single-occurrence" or "recurrent"
  final AlarmMetadata metadata;
  final String kind; // Always "alarm"

  AlarmPayload({
    required this.alarm,
    required this.sourceApp,
    required this.recurrenceType,
    required this.metadata,
    this.kind = 'alarm',
  });

  Map<String, dynamic> toJson() => {
        'alarm': alarm,
        'source_app': sourceApp,
        'recurrence_type': recurrenceType,
        'metadata': metadata.toJson(),
        'kind': kind,
      };

  factory AlarmPayload.fromJson(Map<String, dynamic> json) {
    final recurrenceType = json['recurrence_type'] as String;
    final metadataJson = json['metadata'] as Map<String, dynamic>;

    AlarmMetadata metadata;
    if (recurrenceType == 'single-occurrence') {
      metadata = SingleAlarmMetadata.fromJson(metadataJson);
    } else {
      metadata = RecurrentAlarmMetadata.fromJson(metadataJson);
    }

    return AlarmPayload(
      alarm: json['alarm'] as String,
      sourceApp: json['source_app'] as String,
      recurrenceType: recurrenceType,
      metadata: metadata,
      kind: json['kind'] as String? ?? 'alarm',
    );
  }
}

/// Delete payload for removing alarms
class DeletePayload {
  final String id;
  final String sourceApp;
  final Map<String, dynamic> metadata;

  DeletePayload({
    required this.id,
    required this.sourceApp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source_app': sourceApp,
        'metadata': metadata,
      };

  factory DeletePayload.fromJson(Map<String, dynamic> json) {
    return DeletePayload(
      id: json['id'] as String,
      sourceApp: json['source_app'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
