import 'package:flutter/material.dart';
import 'package:epansa_app/data/models/note.dart';
import 'package:epansa_app/data/models/api/note_api_converter.dart';
import 'package:epansa_app/data/repositories/note_repository.dart';
import 'package:epansa_app/data/api/agent_api_client.dart';

/// Provider for managing notes state
class NoteProvider extends ChangeNotifier {
  final NoteRepository _noteRepository;
  final AgentApiClient _apiClient;
  
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasNotes => _notes.isNotEmpty;

  NoteProvider({
    required NoteRepository noteRepository,
    required AgentApiClient apiClient,
  })  : _noteRepository = noteRepository,
        _apiClient = apiClient {
    _loadNotes();
  }

  /// Load notes from repository
  Future<void> _loadNotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _noteRepository.getAllNotes();
    } catch (e) {
      _error = 'Failed to load notes: $e';
      debugPrint('Error loading notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh notes from repository
  Future<void> refreshNotes() async {
    await _loadNotes();
  }

  /// Create a new note
  Future<Note?> createNote({
    String? title,
    required String text,
  }) async {
    try {
      final note = Note.create(
        title: title,
        text: text,
      );

      // Save locally
      await _noteRepository.saveNote(note);
      
      // Sync to backend
      await _syncNoteToBackend(note);
      
      // Reload notes
      await _loadNotes();
      
      return note;
    } catch (e) {
      _error = 'Failed to create note: $e';
      debugPrint('Error creating note: $e');
      notifyListeners();
      return null;
    }
  }

  /// Update an existing note
  Future<bool> updateNote(Note note) async {
    try {
      // Update modification date
      final updatedNote = note.copyWith(
        dateModified: DateTime.now(),
        isSyncedToBackend: false, // Mark as unsynced since it changed
      );

      // Save locally
      await _noteRepository.saveNote(updatedNote);
      
      // Sync to backend
      await _syncNoteToBackend(updatedNote);
      
      // Reload notes
      await _loadNotes();
      
      return true;
    } catch (e) {
      _error = 'Failed to update note: $e';
      debugPrint('Error updating note: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      // Delete from backend first
      await _apiClient.deleteNote(noteId);
      
      // Delete locally
      await _noteRepository.deleteNote(noteId);
      
      // Reload notes
      await _loadNotes();
      
      return true;
    } catch (e) {
      _error = 'Failed to delete note: $e';
      debugPrint('Error deleting note: $e');
      notifyListeners();
      return false;
    }
  }

  /// Sync a note to backend (add or update)
  Future<void> _syncNoteToBackend(Note note) async {
    try {
      final payload = NoteApiConverter.toApiPayload(note);
      
      // If note has never been synced, add it. Otherwise, update it.
      if (note.lastSyncedAt == null) {
        await _apiClient.addNote(payload);
      } else {
        await _apiClient.updateNote(payload);
      }
      
      // Mark as synced
      await _noteRepository.markAsSynced(note.id);
      
      debugPrint('Note synced to backend: ${note.id}');
    } catch (e) {
      debugPrint('Error syncing note to backend: $e');
      // Don't rethrow - we want to keep the note locally even if sync fails
    }
  }

  /// Get a single note by ID
  Future<Note?> getNote(String id) async {
    return await _noteRepository.getNote(id);
  }

  /// Search notes by text
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return notes;
    
    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      final titleMatch = note.title?.toLowerCase().contains(lowerQuery) ?? false;
      final textMatch = note.text.toLowerCase().contains(lowerQuery);
      return titleMatch || textMatch;
    }).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
