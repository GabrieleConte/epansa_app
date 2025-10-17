import 'package:epansa_app/data/models/note.dart';
import 'package:epansa_app/data/models/api/note_api_models.dart';

/// Converter for Note to/from API payloads
class NoteApiConverter {
  /// Convert local Note to backend NotePayload
  static NotePayload toApiPayload(Note note) {
    return NotePayload(
      note: note.id,
      title: note.title,
      text: note.text,
      dateCreated: note.dateCreated.toIso8601String(),
      dateModified: note.dateModified.toIso8601String(),
      sourceApp: 'epansa_app',
      kind: 'note',
    );
  }

  /// Convert backend NotePayload to local Note
  static Note fromApiPayload(NotePayload payload) {
    return Note(
      id: payload.note,
      title: payload.title,
      text: payload.text,
      dateCreated: payload.dateCreated != null
          ? DateTime.parse(payload.dateCreated!)
          : DateTime.now(),
      dateModified: payload.dateModified != null
          ? DateTime.parse(payload.dateModified!)
          : DateTime.now(),
      isSyncedToBackend: true,
      lastSyncedAt: DateTime.now(),
    );
  }
}
