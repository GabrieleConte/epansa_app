/// Note API models matching backend Pydantic schemas
/// These models are used for communication with the EPANSA backend note endpoints

/// Note payload matching backend NotePayload
class NotePayload {
  final String note; // Note ID
  final String? title;
  final String text;
  final String? dateCreated; // ISO DateTime string
  final String? dateModified; // ISO DateTime string
  final String? sourceApp;
  final String kind;

  NotePayload({
    required this.note,
    this.title,
    required this.text,
    this.dateCreated,
    this.dateModified,
    this.sourceApp,
    this.kind = 'note',
  });

  Map<String, dynamic> toJson() {
    return {
      'note': note,
      if (title != null) 'title': title,
      'text': text,
      if (dateCreated != null) 'date_created': dateCreated,
      if (dateModified != null) 'date_modified': dateModified,
      if (sourceApp != null) 'source_app': sourceApp,
      'kind': kind,
    };
  }

  factory NotePayload.fromJson(Map<String, dynamic> json) {
    return NotePayload(
      note: json['note'] as String,
      title: json['title'] as String?,
      text: json['text'] as String,
      dateCreated: json['date_created'] as String?,
      dateModified: json['date_modified'] as String?,
      sourceApp: json['source_app'] as String?,
      kind: json['kind'] as String? ?? 'note',
    );
  }
}
