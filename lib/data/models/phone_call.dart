/// Local PhoneCall model
/// Represents a phone call log entry from the device
class PhoneCall {
  final String id; // Unique identifier (typically timestamp + number)
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // Duration in seconds
  final String callDirection; // "incoming", "outgoing", "missed"
  final String? withContact; // Contact name if available
  final String? phoneNumber; // Phone number involved
  final DateTime createdAt;
  final bool isSyncedToBackend; // Track if call has been synced
  final DateTime? lastSyncedAt; // When was it last synced

  PhoneCall({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.callDirection,
    this.withContact,
    this.phoneNumber,
    required this.createdAt,
    this.isSyncedToBackend = false,
    this.lastSyncedAt,
  });

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration,
      'callDirection': callDirection,
      'withContact': withContact,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'isSyncedToBackend': isSyncedToBackend,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory PhoneCall.fromJson(Map<String, dynamic> json) {
    return PhoneCall(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      duration: json['duration'] as int,
      callDirection: json['callDirection'] as String,
      withContact: json['withContact'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSyncedToBackend: json['isSyncedToBackend'] as bool? ?? false,
      lastSyncedAt: json['lastSyncedAt'] != null 
          ? DateTime.parse(json['lastSyncedAt'] as String) 
          : null,
    );
  }

  /// Create a new phone call
  factory PhoneCall.create({
    required String id,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    required int duration,
    required String callDirection,
    String? withContact,
    String? phoneNumber,
  }) {
    final now = DateTime.now();
    return PhoneCall(
      id: id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      callDirection: callDirection,
      withContact: withContact,
      phoneNumber: phoneNumber,
      createdAt: now,
      isSyncedToBackend: false,
      lastSyncedAt: null,
    );
  }

  /// Create a copy with updated fields
  PhoneCall copyWith({
    String? id,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? callDirection,
    String? withContact,
    String? phoneNumber,
    DateTime? createdAt,
    bool? isSyncedToBackend,
    DateTime? lastSyncedAt,
  }) {
    return PhoneCall(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      callDirection: callDirection ?? this.callDirection,
      withContact: withContact ?? this.withContact,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      isSyncedToBackend: isSyncedToBackend ?? this.isSyncedToBackend,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Format duration as "MM:SS" or "HH:MM:SS"
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  String toString() {
    return 'PhoneCall(id: $id, direction: $callDirection, contact: $withContact, duration: $formattedDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneCall && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
