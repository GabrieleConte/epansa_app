import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epansa_app/data/models/note.dart';

/// Repository for managing notes locally
class NoteRepository {
  static const String _notesKey = 'notes';
  static const String _lastSyncKey = 'notes_last_sync';

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.dateModified.compareTo(a.dateModified)); // Most recent first
  }

  /// Get a single note by ID
  Future<Note?> getNote(String id) async {
    final notes = await getAllNotes();
    try {
      return notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a note (create or update)
  Future<void> saveNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getAllNotes();
    
    // Remove existing note with same ID if it exists
    notes.removeWhere((n) => n.id == note.id);
    
    // Add the new/updated note
    notes.add(note);
    
    // Save to SharedPreferences
    final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }

  /// Save multiple notes
  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getAllNotes();
    
    notes.removeWhere((note) => note.id == id);
    
    final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList(_notesKey, notesJson);
  }

  /// Get unsynced notes
  Future<List<Note>> getUnsyncedNotes() async {
    final notes = await getAllNotes();
    return notes.where((note) => !note.isSyncedToBackend).toList();
  }

  /// Mark a note as synced
  Future<void> markAsSynced(String id) async {
    final note = await getNote(id);
    if (note == null) return;
    
    final syncedNote = note.copyWith(
      isSyncedToBackend: true,
      lastSyncedAt: DateTime.now(),
    );
    
    await saveNote(syncedNote);
  }

  /// Mark multiple notes as synced
  Future<void> markMultipleAsSynced(List<String> ids) async {
    final notes = await getAllNotes();
    final now = DateTime.now();
    
    final updatedNotes = notes.map((note) {
      if (ids.contains(note.id)) {
        return note.copyWith(
          isSyncedToBackend: true,
          lastSyncedAt: now,
        );
      }
      return note;
    }).toList();
    
    await saveNotes(updatedNotes);
  }

  /// Mark a note as unsynced (e.g., after modification)
  Future<void> markAsUnsynced(String id) async {
    final note = await getNote(id);
    if (note == null) return;
    
    final unsyncedNote = note.copyWith(
      isSyncedToBackend: false,
    );
    
    await saveNote(unsyncedNote);
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    return timestamp != null 
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Update last sync time
  Future<void> updateLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  /// Clear all notes (for testing/debugging)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notesKey);
    await prefs.remove(_lastSyncKey);
  }
}
