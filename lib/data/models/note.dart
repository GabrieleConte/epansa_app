/// Local note model for storing notes in the app
class Note {
  final String id;
  final String? title;
  final String text;
  final DateTime dateCreated;
  final DateTime dateModified;
  final bool isSyncedToBackend;
  final DateTime? lastSyncedAt;

  Note({
    required this.id,
    this.title,
    required this.text,
    required this.dateCreated,
    required this.dateModified,
    this.isSyncedToBackend = false,
    this.lastSyncedAt,
  });

  /// Create a new note
  factory Note.create({
    String? id,
    String? title,
    required String text,
  }) {
    final now = DateTime.now();
    return Note(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      text: text,
      dateCreated: now,
      dateModified: now,
      isSyncedToBackend: false,
    );
  }

  /// Convert from JSON
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      dateCreated: DateTime.parse(json['date_created'] as String),
      dateModified: DateTime.parse(json['date_modified'] as String),
      isSyncedToBackend: json['is_synced_to_backend'] as bool? ?? false,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'is_synced_to_backend': isSyncedToBackend,
      'last_synced_at': lastSyncedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  Note copyWith({
    String? id,
    String? title,
    String? text,
    DateTime? dateCreated,
    DateTime? dateModified,
    bool? isSyncedToBackend,
    DateTime? lastSyncedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      isSyncedToBackend: isSyncedToBackend ?? this.isSyncedToBackend,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Get formatted date created
  String get formattedDateCreated {
    final now = DateTime.now();
    final difference = now.difference(dateCreated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateCreated.day}/${dateCreated.month}/${dateCreated.year}';
    }
  }

  /// Get formatted date modified
  String get formattedDateModified {
    final now = DateTime.now();
    final difference = now.difference(dateModified);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateModified.day}/${dateModified.month}/${dateModified.year}';
    }
  }

  /// Get preview text (first 100 characters)
  String get previewText {
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }
}
