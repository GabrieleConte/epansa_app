/// Model representing a user-created alarm
class Alarm {
  final String id;
  final int hour; // 0-23
  final int minute; // 0-59
  final String label;
  final bool enabled;
  final List<int> repeatDays; // 1=Monday, 7=Sunday (empty = one-time, used for weekly)
  final String? repeatFrequency; // null (one-time), "daily", "weekly", "monthly", "yearly"
  final String? repeatOn; // Used for monthly/yearly: "15", "3 TU", "11-Sep", etc.
  final DateTime createdAt;
  final DateTime? updatedAt;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.enabled,
    required this.repeatDays,
    this.repeatFrequency,
    this.repeatOn,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a new alarm with generated ID and timestamp
  factory Alarm.create({
    required int hour,
    required int minute,
    required String label,
    required bool enabled,
    required List<int> repeatDays,
    String? repeatFrequency,
    String? repeatOn,
  }) {
    return Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hour: hour,
      minute: minute,
      label: label,
      enabled: enabled,
      repeatDays: repeatDays,
      repeatFrequency: repeatFrequency,
      repeatOn: repeatOn,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with updated fields
  Alarm copyWith({
    String? id,
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    List<int>? repeatDays,
    String? repeatFrequency,
    String? repeatOn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      repeatDays: repeatDays ?? this.repeatDays,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      repeatOn: repeatOn ?? this.repeatOn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'minute': minute,
      'label': label,
      'enabled': enabled,
      'repeatDays': repeatDays,
      'repeatFrequency': repeatFrequency,
      'repeatOn': repeatOn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String,
      enabled: json['enabled'] as bool,
      repeatDays: (json['repeatDays'] as List<dynamic>).cast<int>(),
      repeatFrequency: json['repeatFrequency'] as String?,
      repeatOn: json['repeatOn'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  /// Format time as HH:MM
  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Get readable repeat days string
  String get repeatDaysString {
    // Handle different repeat frequencies
    if (repeatFrequency == null || repeatFrequency == 'once') {
      return 'Once';
    }
    
    if (repeatFrequency == 'daily') {
      return 'Every day';
    }
    
    if (repeatFrequency == 'monthly') {
      if (repeatOn != null && repeatOn!.isNotEmpty) {
        return 'Monthly on $repeatOn';
      }
      return 'Monthly';
    }
    
    if (repeatFrequency == 'yearly') {
      if (repeatOn != null && repeatOn!.isNotEmpty) {
        return 'Yearly on $repeatOn';
      }
      return 'Yearly';
    }
    
    // Weekly frequency - use repeatDays
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = repeatDays.map((d) => dayNames[d - 1]).join(', ');
    return days;
  }

  @override
  String toString() {
    return 'Alarm(id: $id, time: $formattedTime, label: $label, enabled: $enabled, repeat: $repeatDaysString)';
  }
}
