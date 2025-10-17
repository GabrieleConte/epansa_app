import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epansa_app/providers/note_provider.dart';
import 'package:epansa_app/data/models/note.dart';

/// Note editor screen - create or edit a note
class NoteEditorScreen extends StatefulWidget {
  final String? noteId; // If null, create new note

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Note? _note;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
    
    // Add listeners to detect changes
    _titleController.addListener(_onContentChanged);
    _textController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Load existing note or prepare for new note
  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      final noteProvider = context.read<NoteProvider>();
      _note = await noteProvider.getNote(widget.noteId!);
      
      if (_note != null) {
        _titleController.text = _note!.title ?? '';
        _textController.text = _note!.text;
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  /// Handle content changes - trigger auto-save after user stops typing
  void _onContentChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
    
    // Cancel previous timer
    _autoSaveTimer?.cancel();
    
    // Start new timer - save after 2 seconds of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_hasUnsavedChanges) {
        _saveNote(silent: true);
      }
    });
  }

  /// Save the note
  Future<void> _saveNote({bool silent = false, bool pop = false}) async {
    if (!_formKey.currentState!.validate()) return;
    
    final text = _textController.text.trim();
    if (text.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note text cannot be empty'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final noteProvider = context.read<NoteProvider>();
      final title = _titleController.text.trim();
      
      if (_note == null) {
        // Create new note
        _note = await noteProvider.createNote(
          title: title.isEmpty ? null : title,
          text: text,
        );
        
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note created'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Update existing note
        final updatedNote = _note!.copyWith(
          title: title.isEmpty ? null : title,
          text: text,
        );
        
        final success = await noteProvider.updateNote(updatedNote);
        
        if (success) {
          _note = updatedNote;
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note updated'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }
        } else if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update note'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      setState(() {
        _hasUnsavedChanges = false;
      });
      
      if (pop && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Handle back button - save before exiting
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges && _textController.text.trim().isNotEmpty) {
      await _saveNote(silent: true);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.noteId == null ? 'New Note' : 'Edit Note'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveNote(pop: true),
                tooltip: 'Save note',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Title (optional)',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const Divider(),
                      // Text field
                      Expanded(
                        child: TextFormField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Start typing...',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 16),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        ),
                      ),
                      // Metadata footer
                      if (_note != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Modified ${_note!.formattedDateModified}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              if (!_note!.isSyncedToBackend)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 14,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Syncing...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_done,
                                      size: 14,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Synced',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
