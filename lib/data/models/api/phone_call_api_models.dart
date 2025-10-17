/// Phone Call API models matching backend Pydantic schemas
/// These models are used for communication with the EPANSA backend

/// Phone call metadata matching backend PhoneCallMetadata
class PhoneCallMetadata {
  final String date; // Format: YYYY-MM-DD
  final String startTime; // ISO time format (HH:MM:SS)
  final String endTime; // ISO time format (HH:MM:SS)
  final String duration; // Duration as formatted string (e.g., "05:30")
  final String callDirection; // "incoming", "outgoing", "missed"
  final String? withContact; // Optional contact name

  PhoneCallMetadata({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.callDirection,
    this.withContact,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'call_direction': callDirection,
      if (withContact != null) 'with_contact': withContact,
    };
  }

  factory PhoneCallMetadata.fromJson(Map<String, dynamic> json) {
    return PhoneCallMetadata(
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      duration: json['duration'] as String,
      callDirection: json['call_direction'] as String,
      withContact: json['with_contact'] as String?,
    );
  }
}

/// Phone call payload matching backend PhoneCallPayload
class PhoneCallPayload {
  final String call; // Call ID (uses alias "call" in backend)
  final String sourceApp;
  final PhoneCallMetadata metadata;
  final String kind;

  PhoneCallPayload({
    required this.call,
    required this.sourceApp,
    required this.metadata,
    this.kind = 'call',
  });

  Map<String, dynamic> toJson() {
    return {
      'call': call,
      'source_app': sourceApp,
      'metadata': metadata.toJson(),
      'kind': kind,
    };
  }

  factory PhoneCallPayload.fromJson(Map<String, dynamic> json) {
    return PhoneCallPayload(
      call: json['call'] as String,
      sourceApp: json['source_app'] as String,
      metadata: PhoneCallMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      kind: json['kind'] as String? ?? 'call',
    );
  }
}
