/// Local Contact model
/// Represents a contact stored on the device
class Contact {
  final String id; // Unique identifier
  final String name;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSyncedToBackend; // Track if contact has been synced
  final DateTime? lastSyncedAt; // When was it last synced

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.isSyncedToBackend = false,
    this.lastSyncedAt,
  });

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSyncedToBackend': isSyncedToBackend,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSyncedToBackend: json['isSyncedToBackend'] as bool? ?? false,
      lastSyncedAt: json['lastSyncedAt'] != null 
          ? DateTime.parse(json['lastSyncedAt'] as String) 
          : null,
    );
  }

  /// Create a new contact
  factory Contact.create({
    required String id,
    required String name,
    required String phoneNumber,
  }) {
    final now = DateTime.now();
    return Contact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      createdAt: now,
      updatedAt: now,
      isSyncedToBackend: false,
      lastSyncedAt: null,
    );
  }

  /// Create a copy with updated fields
  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSyncedToBackend,
    DateTime? lastSyncedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSyncedToBackend: isSyncedToBackend ?? this.isSyncedToBackend,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return 'Contact(id: $id, name: $name, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
